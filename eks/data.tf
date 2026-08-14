data "aws_ssm_parameter" "vpc_id" {
  name = "/simple_social/${var.environment}/vpc/vpc_id"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "/simple_social/${var.environment}/vpc/private_subnets"
}


data "aws_kms_alias" "secrets_manager_kms_key_arn" {
  name = "alias/aws/secretsmanager"
}

data "aws_ssm_parameter" "eci_endpoint_sg_id" {
  name = "/simple_social/${var.environment}/vpc/eci_endpoint_sg_id"
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::simple-social",
      "arn:aws:s3:::simple-social/*"
    ]
  }
}