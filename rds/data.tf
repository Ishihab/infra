
data "aws_ssm_parameter" "database_subnet_group_name" {
  name = "/simple_social/${var.environment}/vpc/db_subnet_group_name"
}

data "aws_ssm_parameter" "db_sg_id" {
  name = "/simple_social/${var.environment}/vpc/db_sg_id"
}




