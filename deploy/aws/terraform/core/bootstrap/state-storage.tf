resource "aws_s3_bucket" "terraform-state-core" {
  # The bucket name needs to be *globally* unique over the WHOLE of AWS, hence using org_domain_name-environment_name which should be unique for us
  bucket        = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-terraform-state"
  acl           = "private"
  force_destroy = true
  versioning {
    enabled     = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
  lifecycle {
    prevent_destroy = true          # cant use variable here for resource_deletion_protection :(
  }
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name            = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-terraform-state"
    Account         = data.aws_caller_identity.current.account_id
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# Set Access Policy on our remote state bucket to Admins Only
#  (cause it could contain passwords or other sensitive info)
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_role" "OrganizationAccountAccessRole" {
  name = "OrganizationAccountAccessRole"
}
module "iam-s3-bucket-policy" {
  source = "git@github.com:davidcallen/terraform-module-iam-s3-bucket-policy-for-users.git?ref=1.0.0"
  # source = "../../../terraform-modules/terraform-module-iam-s3-bucket-policy-for-users"

  bucket_name               =  aws_s3_bucket.terraform-state-core.bucket
  sub_policies = [
    {
      description           = "Restrict access to our terraform-state bucket to Admins"
      actions               = ["s3:*"]
      bucket_paths          = ["", "/*"]
      allowed_user_ids      = [
        "${aws_iam_role.admin.unique_id}:*",
        "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
        var.environment.account_id
      ]
    }
  ]
  root_account_id           = module.global_variables.backbone_account_id
  global_default_tags       = module.global_variables.default_tags
}

# Create a dynamodb table for locking the state file to avoid simultaneous usage by multiple terraform users.
resource "aws_dynamodb_table" "terraform-state-environment" {
  name            = "${var.environment.resource_name_prefix}-terraform-state-locking"
  hash_key        = "LockID"
  billing_mode    = "PROVISIONED"   # PROVISIONED so our minor terraform usage should be covered by Free-Tier
  read_capacity   = 5
  write_capacity  = 5
  attribute {
    name = "LockID"
    type = "S"
  }
  /* server_side_encryption  - DynamoDB is encrypted by default
     ... unless we want to use KMS (but KMS charges will apply)
  server_side_encryption {
    enabled = true
  } */
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name            = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-terraform-state"
    Account         = data.aws_caller_identity.current.account_id
  })
}