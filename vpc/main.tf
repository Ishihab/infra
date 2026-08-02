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

  manage_default_security_group  = true
  default_security_group_egress  = []
  default_security_group_ingress = []

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
  #checkov:skip=CKV2_AWS_19:This EIP is used for NAT Gateway and is required for the VPC to function properly.
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will make upgrades more annoying for a personal project.

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"

  }

}

module "mysql_rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"
  name    = "mysql-rds-sg"
  vpc_id  = module.vpc.vpc_id
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will make upgrades more annoying for a personal project.
  ingress_rules = {
    for cidr_block in module.vpc.private_subnets_cidr_blocks : "mysql-${cidr_block}" => {
      description = "Allow MySQL access from private subnet ${cidr_block}"
      from_port   = 3306
      to_port     = 3306
      ip_protocol = "tcp"
      cidr_ipv4   = cidr_block
      name        = "mysql-${cidr_block}"
    }
  }

}

module "eci_enpoint_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"
  name    = "eci-endpoint-sg"
  vpc_id  = module.vpc.vpc_id
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will make upgrades more annoying for a personal project.
  egress_rules = {
    allow_vpc = {
      description = "Allow HTTPS access to the VPC"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  tags = {
    Name = "eci-endpoint-sg"
  }
}

locals {
  vpc_network_outputs = {
    eci_endpoint_sg_id = {
      type        = "String"
      description = "ID of the security group for the ECI endpoint"
      value       = module.eci_enpoint_sg.id
    }
    db_subnet_group_name = {
      type        = "String"
      description = "List of database subnet IDs"
      value       = module.vpc.database_subnet_group_name
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
    }
    db_sg_id = {
      type        = "String"
      description = "ID of the security group for the RDS instance"
      value       = module.mysql_rds_sg.id
  } }

}

resource "aws_ssm_parameter" "vpc_outputs_for_eks" {
  for_each    = local.vpc_network_outputs
  name        = "/simple_social/${var.environment}/vpc/${each.key}"
  type        = each.value.type
  description = "managed by terraform,env ${var.environment} , ${each.value.description}"
  value       = each.value.value
  #checkov:skip=CKV2_AWS_34:Non sensitive vpc resource references, not sensitive data, no need SecretString type.
}


