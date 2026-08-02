module "eks" {
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will upgrades more annoying for a personal project.
  source             = "terraform-aws-modules/eks/aws"
  version            = "21.24.0"
  name               = var.cluster_name
  subnet_ids         = split(",", data.aws_ssm_parameter.private_subnets.value)
  kubernetes_version = var.kubernetes_version
  #checkov:skip=CKV_AWS_339: EKS support version 1.36, checkov is not updated yet, this is a false positive.
  #checkov:skip=CKV_AWS_58: secrets encryption is enabled by default
  #checkov:skip=CKV_AWS_338: retaining cloudwatch logs for 1 year is overkill for this project 
  endpoint_private_access                  = var.endpoint_private_access
  endpoint_public_access                   = var.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  vpc_id                                   = data.aws_ssm_parameter.vpc_id.value
  cloudwatch_log_group_class               = "standard"
  enabled_log_types                        = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  create_security_group = false
  #checkov:skip=CKV2_AWS_5: security group is managed by eks
  security_group_additional_rules = {
    eci_endpoint = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = data.aws_ssm_parameter.eci_endpoint_sg_id.value
  } }
  compute_config = {
    enabled = false
  }
  addons = {
    coredns = {}
    aws-ebs-csi-driver = {
      most_recent = true
      pod_identity_association = [{
        role_arn        = module.ebs_csi_driver_pod_identity_role_policy.arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  eks_managed_node_groups = {
    default = {
      ami_type                   = "AL2023_x86_64_STANDARD"
      instance_types             = ["t3.medium"]
      enable_bootstrap_user_data = false
      metadata_options = {
        http_put_response_hop_limit = 2
        #checkov:skip=CKV_AWS_341: hop limit of 2 required to allow Pods to access node credentials. alb controller need vpc id from node metadata to function properly.
        #checkov:skip=CKV_AWS_79: Instance Metadata Service Version 1 is not enabled
        #checkov:skip=CKV_AWS_111: managed policy for EKS nodes, not custom, many of its actions don't support resource-level ARNs
        #checkov:skip=CKV_AWS_356: managed policy for EKS nodes, not custom, many of its actions don't support resource-level ARNs
        #checkov:skip=CKV2_AWS_5: security group is managed by eks
        http_tokens = "required"

      }


      min_size              = 1
      max_size              = 3
      desired_size          = 2
      create_security_group = false
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
      type        = "SecureString"
      description = "The endpoint for the EKS cluster"
      value       = module.eks.cluster_endpoint
    }
    cluster_ca_certificate = {
      type        = "SecureString"
      description = "The base64 encoded certificate data required to communicate with the cluster"
      value       = module.eks.cluster_certificate_authority_data
    }

    cluster_name = {
      type        = "SecureString"
      description = "The name of the EKS cluster"
      value       = module.eks.cluster_name
    }
    cluster_arn = {
      type        = "SecureString"
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
  #checkov:skip=CKV2_AWS_34:All eks data in ssm already encrypted 
}

