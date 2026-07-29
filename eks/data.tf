data "aws_ssm_parameter" "vpc_id" {
  name = "/simple_social/${var.environment}/vpc/vpc_id"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "/simple_social/${var.environment}/vpc/private_subnets"
}


