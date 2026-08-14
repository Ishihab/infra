module "ecr" {
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will upgrades complex 
  source          = "terraform-aws-modules/ecr/aws"
  version         = "3.2.0"
  repository_name = "gitops-infra-terraform-ecr"

  repository_read_write_access_arns = ["arn:aws:iam::012345678901:role/terraform"]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus   = "tagged",
          countType   = "imageCountMoreThan",
          countNumber = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}