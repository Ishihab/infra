module "aws_lb_controller_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = data.aws_ssm_parameter.cluster_name.value
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

}


module "external_secrets_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "external-secrets"

  attach_external_secrets_policy        = true
  external_secrets_ssm_parameter_arns   = ["arn:aws:ssm:*:*:parameter/simple_social/*"]
  external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:*:*:secret:*"]
  external_secrets_kms_key_arns         = [data.aws_kms_alias.secrets_manager_kms_key_arn.arn]
  external_secrets_create_permission    = true

  associations = {
    this = {
      cluster_name    = data.aws_ssm_parameter.cluster_name.value
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }

}

module "ebs_csi_driver_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "ebs-csi-driver"

  attach_aws_ebs_csi_policy = true

  associations = {
    this = {
      cluster_name    = data.aws_ssm_parameter.cluster_name.value
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

}