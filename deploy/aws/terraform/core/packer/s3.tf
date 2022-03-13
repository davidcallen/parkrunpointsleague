
# ---------------------------------------------------------------------------------------------------------------------
# Packer files : used by Packer ONLY in building AMIs (no general access by users)
# AWS Accounts that are allowed to be packer builders (to generate AMIs)
# will have access to certain core facilities like s3 bucket for packer software installer files.
# Although some of these files may also be available for adhoc usage by human users, they are duplicated here to ensure safe and trusted.
# Method for IAM Access to this bucket is based on article : https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html
# ---------------------------------------------------------------------------------------------------------------------
locals {
  packer_files_allow_account_ids = sort(concat(var.packer_builder_account_ids, [var.environment.account_id, var.backbone_account_id]))
}
resource "aws_s3_bucket" "packer-files" {
  bucket        = "${var.org_domain_name}-${var.environment.resource_name_prefix}-packer-files"
  force_destroy = true
  lifecycle {
    prevent_destroy = false # cant use variable here for resource_deletion_protection :(
  }
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name = "${var.org_domain_name}-${var.environment.resource_name_prefix}-packer-files"
  })
}
resource "aws_s3_bucket_versioning" "vpc-flow-logs" {
  bucket = aws_s3_bucket.packer-files.id
  versioning_configuration {
    status = "Suspended"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc-flow-logs" {
  bucket = aws_s3_bucket.packer-files.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_policy" "vpc-flow-logs" {
  bucket = aws_s3_bucket.packer-files.bucket
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        Sid       = "Deny ALL access to all except Admins and packer-files Roles",
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:List*",
          "s3:GetObject*"
        ]
        Resource = [
          "arn:aws:s3:::${var.org_domain_name}-${var.environment.resource_name_prefix}-packer-files",
          "arn:aws:s3:::${var.org_domain_name}-${var.environment.resource_name_prefix}-packer-files/*",
        ]
        Condition = {
          StringNotLike = {
            "aws:userId" = [
              "${data.aws_iam_role.admin-role.unique_id}:*",
              "${aws_iam_role.packer-files-s3-read.unique_id}:*",
              # assumed role id is "UNIQUE-ROLE-ID:ROLE-SESSION-NAME"
              "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
              var.backbone_account_id
            ]
          }
        }
      }
    ]
  })
}
data "aws_iam_role" "admin-role" {
  name = "${var.environment.resource_name_prefix}-admin"
}
data "aws_iam_role" "OrganizationAccountAccessRole" {
  name = "OrganizationAccountAccessRole"
}
# ---------------------------------------------------------------------------------------------------------------------
# Software installer files needed by Packer AMI builds : IBM MQ Websphere, IBM ILMT BigFix Agent, and BigFix Console, ...
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_object" "packer-files-upload" {
  for_each = fileset("${path.module}/../../../../files-for-uploading/${var.org_short_name}/${var.environment.name}/packer-files/", "**")

  bucket = aws_s3_bucket.packer-files.id
  key    = each.value
  source = "${path.module}/../../../../files-for-uploading/${var.org_short_name}/${var.environment.name}/packer-files/${each.value}"
  etag   = filemd5("${path.module}/../../../../files-for-uploading/${var.org_short_name}/${var.environment.name}/packer-files/${each.value}")
}
