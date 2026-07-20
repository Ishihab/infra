data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.azs.names, 0, min(length(data.aws_availability_zones.azs.names), 3))
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "6.6.1"
    name = var.vpc_name
    cidr = var.vpc_cidr
    enable_ipv6 = var.enable_ipv6
    
    enable_dns_hostnames = true
    enable_dns_support = true

    azs =  local.azs
    public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
    private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 3)]
    database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 6)]
    create_private_nat_gateway_route = var.create_private_nat_gateway_route
    database_subnet_group_name = "${var.vpc_name}-db-subnet-group"
    create_database_subnet_group = var.create_database_subnet_group

    enable_nat_gateway = true
    single_nat_gateway = var.single_nat_gateway
    one_nat_gateway_per_az = var.one_nat_gateway_per_az

    public_subnet_tags = {
        "kubernetes.io/role/elb" = 1
    }

    private_subnet_tags = {
        "kubernetes.io/role/internal-elb" = 1
        
    }

}




