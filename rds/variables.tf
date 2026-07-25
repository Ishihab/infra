variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
  
}

variable "environment" {
  description = "The environment for the EKS cluster (e.g., dev, staging, prod)"
  type        = string

}

variable "db_identifier" {
  description = "The identifier for the RDS database instance"
  type        = string
}

variable "db_engine" {
  description = "The database engine for the RDS instance (e.g., mysql, postgres)"
  type        = string
}

variable "db_engine_version" {
  description = "The version of the database engine for the RDS instance"
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the RDS database instance"
  type        = string
}

variable "db_name" {
  description = "The name of the database to create when the RDS instance is created"
  type        = string
}

variable "db_username" {
  description = "The username for the database master user"
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes for the RDS instance"
  type        = number
}

