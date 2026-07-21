data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.azs.names, 0, min(length(data.aws_availability_zones.azs.names), 3))
}

module "vpc" {
  source      = "terraform-aws-modules/vpc/aws"
  version     = "6.6.1"
  name        = var.vpc_name
  cidr        = var.vpc_cidr
  enable_ipv6 = var.enable_ipv6

  enable_dns_hostnames = true
  enable_dns_support   = true

  azs                              = local.azs
  public_subnets                   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  private_subnets                  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 3)]
  database_subnets                 = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 6)]
  create_private_nat_gateway_route = var.create_private_nat_gateway_route
  database_subnet_group_name       = "${var.vpc_name}-db-subnet-group"
  create_database_subnet_group     = var.create_database_subnet_group

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1

  }

}

locals {
  vpc_network_outputs = {
  db_subnet_group_name = {
    type        = "String"
    description = "Name of the database subnet group"
    value       = join(",", module.vpc.database_subnets)
  }
  vpc_id = {
    type        = "String"
    description = "ID of the VPC"
    value       = module.vpc.vpc_id
  }
  private_subnets = {
    type        = "StringList"
    description = "List of private subnet IDs"
    value       = join(",", module.vpc.private_subnets)
  }
  public_subnets = {
    type        = "StringList"
    description = "List of public subnet IDs"
    value       = join(",", module.vpc.public_subnets)
  }}
}

resource "aws_ssm_parameter" "vpc_outputs_for_eks" {
  for_each    = local.vpc_network_outputs
  name        = "/simple_social/${var.environment}/vpc/${each.key}"
  type        = each.value.type
  description = "managed by terraform,env ${var.environment} , ${each.value.description}"
  value       = each.value.value
  tags = {
    "managed_by"  = "terraform"
    "environment" = var.environment
  }

}


