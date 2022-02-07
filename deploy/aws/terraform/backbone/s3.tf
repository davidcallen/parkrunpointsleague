# ---------------------------------------------------------------------------------------------------------------------
# S3 storage
# ---------------------------------------------------------------------------------------------------------------------

# Account wide block of public access
resource "aws_s3_account_public_access_block" "s3-account-wide-public-access-block" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
//
//# ---------------------------------------------------------------------------------------------------------------------
//# VPC Flow Logs (long-term storage)
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_s3_bucket" "vpc-flow-logs" {
//  bucket        = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-vpc-flow-logs"
//  acl           = "private"
//  force_destroy = true
//  versioning {
//    enabled = false
//  }
//  server_side_encryption_configuration {
//    rule {
//      apply_server_side_encryption_by_default {
//        sse_algorithm     = "AES256"
//      }
//    }
//  }
//  policy = <<EOF
//{
//    "Version": "2012-10-17",
//    "Statement": [
//      {
//          "Sid": "1",
//          "Action": "s3:GetBucketAcl",
//          "Effect": "Allow",
//          "Resource": "arn:aws:s3:::${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-vpc-flow-logs",
//          "Principal": {
//            "Service": "logs.${module.global_variables.aws_region}.amazonaws.com"
//          }
//      },
//      {
//          "Sid": "2",
//          "Action": "s3:PutObject" ,
//          "Effect": "Allow",
//          "Resource": "arn:aws:s3:::${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-vpc-flow-logs/*",
//          "Condition": {
//            "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" }
//          },
//          "Principal": {
//            "Service": "logs.${module.global_variables.aws_region}.amazonaws.com"
//          }
//      },
//      {
//          "Sid": "AWSLogDeliveryWrite",
//          "Effect": "Allow",
//          "Principal": {
//              "Service": "delivery.logs.amazonaws.com"
//          },
//          "Action": "s3:PutObject",
//          "Resource": "arn:aws:s3:::${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-vpc-flow-logs/AWSLogs/${var.environment.account_id}/*",
//          "Condition": {
//              "StringEquals": {
//                  "s3:x-amz-acl": "bucket-owner-full-control"
//              }
//          }
//      },
//      {
//          "Sid": "AWSLogDeliveryAclCheck",
//          "Effect": "Allow",
//          "Principal": {
//              "Service": "delivery.logs.amazonaws.com"
//          },
//          "Action": "s3:GetBucketAcl",
//          "Resource": "arn:aws:s3:::${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-vpc-flow-logs"
//      }
//    ]
//}
//EOF
//  lifecycle_rule {
//    id              = "Ageing"
//    enabled         = true
//    prefix          = "*"
//    tags = {
//      "rule"        = "Ageing"
//      "autoclean"   = "true"
//    }
//    transition {
//      days          = 60
//      storage_class = "STANDARD_IA"
//    }
//    transition {
//      days          = 90
//      storage_class = "GLACIER"
//    }
//    expiration {
//      days          = 360
//    }
//  }
//  lifecycle {
//    prevent_destroy = true          # cant use variable here for resource_deletion_protection :(
//  }
//  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
//    Name            = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-vpc-flow-logs"
//    Description     = "Contains VPC Flow Logs. These Logs also in Cloudwatch but in S3 held for longer rentention period for cost saving."
//  })
//}
//
