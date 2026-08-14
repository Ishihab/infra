module "mysql_rds" {
  #checkov:skip=CKV_TF_1:This module are well maintained official public terraform module, using sha will upgrades more annoying.
  source                      = "terraform-aws-modules/rds/aws"
  version                     = "6.13.1"
  identifier                  = var.db_identifier
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  family                      = "${var.db_engine}${split(".", var.db_engine_version)[0]}"
  major_engine_version        = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  db_name                     = var.db_name
  username                    = var.db_username
  copy_tags_to_snapshot       = true
  manage_master_user_password = true
  vpc_security_group_ids      = [data.aws_ssm_parameter.db_sg_id.value]
  db_subnet_group_name        = data.aws_ssm_parameter.database_subnet_group_name.value
  multi_az                    = false
  publicly_accessible         = false
  #checkov:skip=CKV_AWS_338:Overkill for a personal project, there is a charge for this
  #checkov:skip=CKV_AWS_293:Destroying later will be complicated, this is a personal project, not production.
  #checkov:skip=CKV_AWS_157:multi_az will double the cost, single az is enough for a personal project
  #checkov:skip=CKV_AWS_304:This is a personal project, not production, so we can skip this check.
  skip_final_snapshot             = true
  deletion_protection             = false
  cloudwatch_log_group_class      = "STANDARD"
  database_insights_mode          = "standard"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  performance_insights_enabled    = true
  #checkov:skip=CKV_AWS_354:Aws managed KMS key is fine for this size of porject, unless there is strict compliance requirement, no need to create a custom kms key.
  monitoring_interval    = 60
  create_monitoring_role = true
  #checkov:skip=CKV2_AWS_30:query logging is already enabled 
  parameters = [
    {
      name  = "log_statements"
      value = "all"
    },

    {
      name  = "log_min_duration_statement"
      value = "2000"
    },

    {
      name  = "log_destination"
      value = "stderr"
    },

    {
      name  = "timezone"
      value = "UTC"
  }]

}

locals {
  db_outputs = {
    db_name = {
      type        = "SecureString"
      description = "The name of the database"
      value       = module.mysql_rds.db_instance_name
    }
    db_endpoint = {
      type        = "SecureString"
      description = "The endpoint of the database"
      value       = module.mysql_rds.db_instance_endpoint
    }
    db_username = {
      type        = "SecureString"
      description = "The username for the database"
      value       = module.mysql_rds.db_instance_username
    }
    db_master_user_secret_arn = {
      type        = "SecureString"
      description = "The ARN of the secret for the database master user"
      value       = module.mysql_rds.db_instance_master_user_secret_arn
    }
  }
}



resource "aws_ssm_parameter" "db_outputs_for_eks" {
  for_each    = local.db_outputs
  name        = "/simple_social/${var.environment}/rds/${each.key}"
  type        = each.value.type
  description = "managed by terraform,env ${var.environment} , ${each.value.description}"
  value       = each.value.value
  #checkov:skip=CKV2_AWS_34:All rds data in ssm already encrypted
  #checkov:skip=CKV_AWS_337:aws managed kms key is fine for this size of porject, unless there is strict compliance requirement, no need to create a custom kms key.
}



