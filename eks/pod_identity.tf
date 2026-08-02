
module "aws_lb_controller_pod_identity" {
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will upgrades more annoying for a personal project.
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.8.1"
  name    = "aws-lbc"

  attach_aws_lb_controller_policy = true
  #checkov:skip=CKV_AWS_356: AWS-managed LB controller policy (attach_aws_lb_controller_policy); many of its actions don't support resource-level ARNs — this is the AWS-published policy, not custom
  #checkov:skip=CKV_AWS_111: AWS-managed LB controller policy (attach_aws_lb_controller_policy); many of its actions don't support resource-level ARNs — this is the AWS-published policy, not custom
  #checkov:skip=CKV_AWS_109: AWS-managed LB controller policy (attach_aws_lb_controller_policy); many of its actions don't support resource-level ARNs — this is the AWS-published policy, not custom
  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
  depends_on = [module.eks]
}


module "external_secrets_pod_identity" {
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will upgrades more annoying for a personal project.
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.8.1"
  name    = "external-secrets"

  attach_external_secrets_policy = true
  #checkov:skip=CKV_AWS_356: AWS-managed External Secrets policy (attach_external_secrets_policy); many of its actions don't support resource-level ARNs — this is the AWS-published policy, not custom
  #checkov:skip=CKV_AWS_111: AWS-managed External Secrets policy (attach_external_secrets_policy); many of its actions don't support resource-level ARNs — this is the AWS-published policy, not custom
  #checkov:skip=CKV_AWS_109: AWS-managed External Secrets policy (attach_external_secrets_policy); many of its actions don't support resource-level ARNs — this is the AWS-published policy, not custom
  external_secrets_ssm_parameter_arns   = ["arn:aws:ssm:*:*:parameter/simple_social/*"]
  external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:*:*:secret:*"]
  external_secrets_kms_key_arns         = [data.aws_kms_alias.secrets_manager_kms_key_arn.arn]
  external_secrets_create_permission    = true

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }
  depends_on = [module.eks]
}

module "ebs_csi_driver_pod_identity_role_policy" {
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will upgrades more annoying for a personal project.
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"
  name    = "ebs-csi-driver-role"
  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      principals = [{
        type = "Service"
        identifiers = [
          "pods.eks.amazonaws.com"
        ]
      }]
    }
  }
  policies = {

    ebs-csi-driver-policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

  }
}

