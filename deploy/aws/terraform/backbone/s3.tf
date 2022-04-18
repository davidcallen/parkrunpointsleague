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
