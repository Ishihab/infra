provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Terraform   = "true"
    }
  }
}

provider "kubectl" {
  host                   = data.aws_ssm_parameter.cluster_endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca_cert.value)
  load_config_file        = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster_name.value]
  }
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_ssm_parameter.cluster_endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca_cert.value)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster_name.value]
      command     = "aws"
    }
  }
}

