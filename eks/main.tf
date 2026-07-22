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
  enable_irsa                              = var.enable_irsa
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

locals {
  eks_outputs = {
    cluster_endpoint = {
      type        = "String"
      description = "The endpoint for the EKS cluster"
      value       = module.eks.cluster_endpoint
    }
    oidc_prodvider_arn = {
      type        = "String"
      description = "The ARN of the OIDC provider for the EKS cluster"
      value       = module.eks.oidc_provider_arn
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
    oidc_provider_url = {
      type        = "String"
      description = "The URL of the OIDC provider for the EKS cluster"
      value       = module.eks.oidc_provider
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
  tags = {
    "managed_by"  = "terraform"
    "environment" = var.environment
  }


}

