# ---------------------------------------------------------------------------------------------------------------------
# ECR : Container Repository
# ---------------------------------------------------------------------------------------------------------------------
locals {
  repository_names = [
    "${module.global_variables.org_domain_name}/prpl-base",
    "${module.global_variables.org_domain_name}/prpl-builder",
    "${module.global_variables.org_domain_name}/prpl"
  ]
}
# AWS And ECR requires a Repository for each image  (seems wierd).
resource "aws_ecr_repository" "ecr-docker-repo" {
  count                = length(local.repository_names)
  name                 = local.repository_names[count.index]
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
resource "aws_ecr_repository_policy" "ecr-docker-repo" {
  count      = length(local.repository_names)
  repository = aws_ecr_repository.ecr-docker-repo[count.index].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AuthorDockerImages"
        Effect = "Allow"
        Principal = {
          AWS = [
            # AWS = "arn:aws:iam::${var.environment.account_id}:role/prpl-${var.environment.name}-admin"
            "arn:aws:iam::${var.environment.account_id}:user/david",  # TODO - change IAM so can use admin role
            "arn:aws:iam::597767386394:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
            ]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
      }
    ]
  })
}
# Allow public images e.g. dockerhub to be pulled through our repos
resource "aws_ecr_pull_through_cache_rule" "ecr-docker-repo" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}