module "ecr" {
  #checkov:skip=CKV_TF_1:This module are well maintained public terraform module, using sha will upgrades complex 
  source                            = "terraform-aws-modules/ecr/aws"
  version                           = "3.2.0"
  repository_name                   = "gitops-infra-terraform-ecr"
  repository_image_tag_mutability   = "IMMUTABLE_WITH_EXCLUSION"
  repository_read_write_access_arns = [module.github_oidc_role_for_ecr.arn]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 sha-tagged images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["sha-"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  repository_image_tag_mutability_exclusion_filter = [
    {
      filter      = "latest"
      filter_type = "WILDCARD"
    }
  ]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



