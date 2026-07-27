variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"

}

variable "environment" {
  description = "The environment for the EKS cluster (e.g., dev, staging, prod)"
  type        = string

}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.36"
}

variable "enable_irsa" {
  description = "Whether to enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether to enable private access to the EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether to enable public access to the EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Whether to grant the cluster creator admin permissions"
  type        = bool
  default     = true
}