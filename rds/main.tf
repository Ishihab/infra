module "mysql_rds" {
  source                       = "terraform-aws-modules/rds/aws"
  version                      = "6.13.1"
  identifier                   = var.db_identifier
  engine                       = var.db_engine
  engine_version               = var.db_engine_version
  family                       = "${var.db_engine}${var.db_engine_version}"
  major_engine_version         = var.db_engine_version
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  db_name                      = var.db_name
  username                     = var.db_username
  manage_master_user_password  = true
  vpc_security_group_ids       = [data.aws_ssm_parameter.db_sg_id.value]
  db_subnet_group_name         = data.aws_ssm_parameter.database_subnet_group_name.value
  multi_az                     = false
  publicly_accessible          = false
  skip_final_snapshot          = true
  deletion_protection          = false
  performance_insights_enabled = false
  monitoring_interval          = 60
  create_monitoring_role       = true
  parameters = [
    {
      name  = "slow_query_log"
      value = "1"
    },

    {
      name  = "long_query_time"
      value = "2"
    },

    {
      name  = "log_output"
      value = "FILE"
    },

    {
      name  = "time_zone"
      value = "UTC"
  }]

}

locals {
  db_outputs = {
    db_name = {
      type        = "String"
      description = "The name of the database"
      value       = module.mysql_rds.db_instance_name
    }
    db_endpoint = {
      type        = "String"
      description = "The endpoint of the database"
      value       = module.mysql_rds.db_instance_endpoint
    }
    db_username = {
      type        = "String"
      description = "The username for the database"
      value       = module.mysql_rds.db_instance_username
    }
    db_master_user_secret_name = {
      type        = "String"
      description = "The ARN of the secret for the database master user"
      value       = split(":secret:", module.mysql_rds.db_instance_master_user_secret_arn)[1]
    }
  }
}



resource "aws_ssm_parameter" "db_outputs_for_eks" {
  for_each    = local.db_outputs
  name        = "/simple_social/${var.environment}/rds/${each.key}"
  type        = each.value.type
  description = "managed by terraform,env ${var.environment} , ${each.value.description}"
  value       = each.value.value

}
