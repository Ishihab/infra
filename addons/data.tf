data "aws_ssm_parameter" "ca_cert" {
  name = "/simple_social/${var.environment}/eks/cluster_ca_certificate"
}

data "aws_ssm_parameter" "cluster_endpoint" {
  name = "/simple_social/${var.environment}/eks/cluster_endpoint"
}


data "aws_ssm_parameter" "cluster_name" {
  name = "/simple_social/${var.environment}/eks/cluster_name"
}




