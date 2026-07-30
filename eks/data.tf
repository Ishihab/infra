data "aws_ssm_parameter" "vpc_id" {
  name = "/simple_social/${var.environment}/vpc/vpc_id"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "/simple_social/${var.environment}/vpc/private_subnets"
}


data "aws_kms_alias" "secrets_manager_kms_key_arn" {
  name = "alias/aws/secretsmanager"
}
