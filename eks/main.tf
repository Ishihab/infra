module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "21.24.0"
  name                                     = var.cluster_name
  subnet_ids                               = split(",", data.aws_ssm_parameter.private_subnets.value)
  kubernetes_version                       = var.kubernetes_version
  endpoint_private_access                  = var.endpoint_private_access
  endpoint_public_access                   = var.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  vpc_id                                   = data.aws_ssm_parameter.vpc_id.value
  compute_config = {
    enabled = false
  }
  addons = {
    coredns = {}
    aws-ebs-csi-driver = {
      most_recent = true
      
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET = "1"
        }
      })
    }
  }
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      enable_bootstrap_user_data = false

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

  timeouts = {
    create = "30m"
    update = "30m"
  }
}

locals {
  eks_outputs = {
    cluster_endpoint = {
      type        = "String"
      description = "The endpoint for the EKS cluster"
      value       = module.eks.cluster_endpoint
    }
    cluster_ca_certificate = {
      type        = "SecureString"
      description = "The base64 encoded certificate data required to communicate with the cluster"
      value       = module.eks.cluster_certificate_authority_data
    }

    cluster_name = {
      type        = "String"
      description = "The name of the EKS cluster"
      value       = module.eks.cluster_name
    }
    cluster_arn = {
      type        = "String"
      description = "The ARN of the EKS cluster"
      value       = module.eks.cluster_arn
    }
  }
}

resource "aws_ssm_parameter" "eks_output" {
  for_each    = local.eks_outputs
  name        = "/simple_social/${var.environment}/eks/${each.key}"
  type        = each.value.type
  description = "managed by terraform,env ${var.environment} , ${each.value.description}"
  value       = each.value.value
}

