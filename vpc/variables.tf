variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "enable_ipv6" {
  description = "Whether to enable IPv6 for the VPC"
  type        = bool
  default     = false
}


variable "create_database_subnet_group" {
  description = "Whether to create a database subnet group"
  type        = bool
  default     = true
}

variable "create_private_nat_gateway_route" {
  description = "Whether to create a private NAT gateway route"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to create a single NAT gateway"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Whether to create one NAT gateway per availability zone"
  type        = bool
  default     = false
}







