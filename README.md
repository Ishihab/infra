# infra

This Reop contain Terraform code that provisions the AWS infrastructure for a self-service GitOps platform on EKS: networking, the cluster itself, a database, and the IAM/Pod Identity roles every platform service needs. The last step it takes is installing Argo CD and pointing it at the companion [`gitops`](https://github.com/Ishihab/gitops.git) repo, which is where platform services and applications actually get deployed from.

`infra` and `gitops` together are the portfolio project: a self-service GitOps platform on EKS. [`simple-social`](https://github.com/Ishihab/simple-social) is a separate FastAPI portfolio project of mine — it isn't part of this platform's infrastructure, it's just used as a real workload to exercise it (its CI builds an image, pushes it to the ECR repo `eks/` provisions here using the OIDC role also provisioned here, and Argo CD deploys it from the `gitops` repo like any other app).

## The two repos that make up this platform

- **[`infra`](https://github.com/Ishihab/infra)** (this repo) — Terraform. Builds the VPC, the EKS cluster, RDS, ECR, and all the IAM/Pod Identity roles the platform services below will need. The final module (`addons/`) installs Argo CD and applies one root `Application` manifest.
- **[`gitops`](https://github.com/Ishihab/gitops.git)** — Argo CD app-of-apps config. `argocd/applications/` holds one `Application` manifest per thing that should run on the cluster: Argo CD itself, the ALB controller, External Secrets, the kube-prometheus-stack, and (as an example consumer app) `simple-social`. The root `Application` created by `addons/` points at this directory, so Argo CD picks up and syncs everything in it automatically.

Once the Terraform in this repo has been applied, the cluster is fully self-service: to deploy a new app, you don't touch Terraform at all — you add an Argo CD `Application` manifest to the `gitops` repo (see [Adding a new application](#adding-a-new-application) below).

## This repo's Terraform modules

Four independent root modules, each with its own state file:

| Directory  | Purpose |
|------------|---------|
| `vpc/`     | VPC, public/private/database subnets, NAT gateway(s), security groups |
| `rds/`     | PostgreSQL database (private, not publicly accessible) |
| `eks/`     | EKS cluster, managed node group, ECR repo, IAM/Pod Identity roles |
| `addons/`  | Argo CD install + root `Application` that points at the `gitops` repo |

Each directory follows the same layout: resource `.tf` files, `variables.tf`, `outputs.tf`, `data.tf`, `providers.tf`, `versions.tf`, `backend.tf`, and `environment/dev.tfvars` for environment-specific values.

## Module details

### `vpc/`

- Module: `terraform-aws-modules/vpc/aws` (v6.6.1)
- VPC (`10.0.0.0/16` by default) with public, private, and database subnets across up to 3 AZs
- NAT gateway(s) for outbound access from private subnets (single NAT by default, configurable per-AZ)
- Security group for RDS (Postgres `5432` from private subnet CIDRs) and an EC2 Instance Connect Endpoint for private-subnet access
- Locks down the VPC default security group (no ingress/egress)
- Writes VPC ID, subnet IDs, and security group IDs to SSM Parameter Store under `/simple_social/<environment>/vpc/*`

### `eks/`

- Module: `terraform-aws-modules/eks/aws` (v21.24.0)
- Reads VPC ID / private subnet IDs from SSM and provisions the cluster into the private subnets
- Managed node group: `t3.medium` (AL2023), autoscaling `min=1 max=3 desired=2`
- Add-ons: `coredns`, `kube-proxy`, `vpc-cni`, `eks-pod-identity-agent`, `aws-ebs-csi-driver`
- Control-plane logging: `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`
- Pod Identity associations, pre-created here so the platform services deployed from the `gitops` repo have AWS access as soon as they're installed:
  - `aws-load-balancer-controller` (`kube-system`) — lets the ALB controller Application create AWS load balancers
  - `external-secrets` (`external-secrets`) — SSM/Secrets Manager/KMS access for the External Secrets Application
  - `ebs-csi-controller-sa` — used by the `aws-ebs-csi-driver` add-on
  - `simple-social` (`simple-social` namespace) — custom policy granting the test app's own service account S3 access
- ECR repo `gitops-infra-terraform-ecr` (lifecycle policy expires old `sha-`tagged images past 30, keeps `latest`) and a GitHub OIDC role scoped to `Ishihab/simple-social` on `main` — this is what the separate `simple-social` app's CI uses to push images into the platform's own ECR, to exercise the ECR + OIDC setup end to end
- Writes cluster endpoint, CA cert, name, and ARN to SSM under `/simple_social/<environment>/eks/*`

### `rds/`

- Module: `terraform-aws-modules/rds/aws` (v6.13.1)
- PostgreSQL `17.10`, `db.t3.medium`, 20 GB storage, single-AZ, deployed into the database subnets, not publicly accessible
- Master password managed via AWS Secrets Manager
- Performance Insights, enhanced monitoring, CloudWatch log exports (`postgresql`, `upgrade`), query logging enabled
- Writes DB name, host, port, username, and master secret ARN to SSM under `/simple_social/<environment>/rds/*`

### `addons/`

- Installs Argo CD via the official Helm chart (`argo-cd` v10.2.1) into the `argocd` namespace, configured through `argocd_values.yaml`
- Applies a root Argo CD `Application` (`root-app.yaml`) pointing at `Ishihab/gitops` (`./argocd/applications`, `main`), with automated sync + prune enabled

That root `Application` is the only thing this repo puts on the cluster directly — everything else comes from Argo CD syncing the `gitops` repo, described next.

## What gets deployed once Argo CD takes over

`addons/root-app.yaml` is an app-of-apps root: Argo CD watches `argocd/applications/` in the `gitops` repo, and every `Application` manifest it finds there gets created and synced automatically — Argo CD itself, the ALB controller, External Secrets, kube-prometheus-stack, and (as an example consumer app) `simple-social`. The current list of applications and how each is wired up lives in the [`gitops` README](https://github.com/Ishihab/gitops#currently-deployed-applications) — that repo owns it, so it doesn't drift out of sync with a second copy here.

## Adding a new application

Deploying a new workload doesn't require touching this repo or the app's own IaC — any app, from any repo, can onboard this way. In short: add an Argo CD `Application` manifest to the `gitops` repo, pointing at the app's own manifests/Kustomize overlay/Helm chart, and push. See the [`gitops` README](https://github.com/Ishihab/gitops#adding-a-new-application) for the full steps, naming conventions, and a worked example.

## State and cross-module dependencies

Each module keeps its own state in a shared S3 backend (state locking via `use_lockfile`, no DynamoDB table needed). Modules don't reference each other's Terraform state directly — instead, `vpc` publishes values to SSM Parameter Store and `eks`/`rds` read them back via `data "aws_ssm_parameter"` lookups.

## CI/CD

Workflows live in `.github/workflows/`:

- **`scan-apply.yaml`** — detects which of `vpc`/`eks`/`rds`/`addons` changed (`dorny/paths-filter`). On PRs: `terraform validate`/`fmt`, `tflint`, `checkov` (static + plan), and posts the plan as a PR comment. On push to `main`: applies each changed module in dependency order (`vpc` → `eks`/`rds` → `addons`).
- **`initial-apply.yaml`** — manually triggered, deploys everything from scratch in order.
- **`destroy.yaml`** — manually triggered, tears everything down in reverse order.

Composite actions used by the workflows above:

- `terraform-setup-cache` — installs Terraform, caches provider plugins
- `terraform-aws-init` — configures AWS OIDC credentials, runs `terraform init` against the S3 backend
- `terraform-static-scan` — `terraform validate`/`fmt`, `tflint`, `checkov`
- `checkov-plan-scan` — runs `checkov` against a plan file

## Getting started

### Prerequisites

- An AWS account and an S3 bucket for Terraform state
- An IAM role assumable by GitHub Actions via OIDC with permissions to manage these resources
- Repository secrets/variables:
  - `AWS_ROLE_ARN` — IAM role ARN for GitHub Actions
  - `BACKEND_BUCKET` — S3 bucket for Terraform state
  - `DB_USERNAME` — RDS master username (secret)
  - `VPC_BACKEND_KEY`, `EKS_BACKEND_KEY`, `RDS_BACKEND_KEY`, `ADDONS_BACKEND_KEY` — per-module state keys

### Deploying

1. **From scratch:** trigger the **Initial Apply** workflow from the Actions tab.
2. **Making changes:** open a PR — `scan-apply.yaml` posts a plan for review; merging to `main` applies it.
3. **Locally:** from within a module directory:
   ```bash
   terraform init
   terraform plan -var-file=./environment/dev.tfvars
   terraform apply -var-file=./environment/dev.tfvars
   ```
