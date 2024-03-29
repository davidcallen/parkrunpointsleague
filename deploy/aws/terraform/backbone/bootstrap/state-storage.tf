data "aws_canonical_user_id" "current_user" {}

resource "aws_s3_bucket" "terraform-state" {
  # The bucket name needs to be *globally* unique over the WHOLE of AWS, hence using org_domain_name-environment_name which should be unique for us
  bucket        = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-terraform-state"
  force_destroy = true
  lifecycle {
    prevent_destroy = true # cant use variable here for resource_deletion_protection :(
  }
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name    = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-terraform-state"
    Account = data.aws_caller_identity.current.account_id
  })
}
resource "aws_s3_bucket_versioning" "terraform-state" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}
# TODO : Do we really need this grant?
#        Was needed in terraform-aws-provider upgrade from 2.47.0 to 2.70.0 - access restriction should be covered by IAM Policy ?
resource "aws_s3_bucket_acl" "terraform-state" {
  bucket = aws_s3_bucket.terraform-state.id
  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current_user.id
        type = "CanonicalUser"
      }
      permission = "READ"
    }
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current_user.id
        type = "CanonicalUser"
      }
      permission = "READ_ACP"
    }
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current_user.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    owner {
      id = data.aws_canonical_user_id.current_user.id
    }
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-state" {
  bucket = aws_s3_bucket.terraform-state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create a dynamodb table for locking the state file to avoid simultaneous usage by multiple terraform users.
resource "aws_dynamodb_table" "terraform-state-environment" {
  name           = "${var.environment.resource_name_prefix}-terraform-state-locking"
  hash_key       = "LockID"
  billing_mode   = "PROVISIONED" # PROVISIONED so our minor terraform usage should be covered by Free-Tier
  read_capacity  = 5
  write_capacity = 5
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
    Name    = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-terraform-state"
    Account = data.aws_caller_identity.current.account_id
  })
}