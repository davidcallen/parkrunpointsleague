# ---------------------------------------------------------------------------------------------------------------------
# KMS Customer Managed CMK Key for encrypting/decrypting our Secrets files
# Only usable by this account. Only usable by Cloud Admins.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "secrets" {
  description             = "${var.environment.resource_name_prefix}-kms-secrets"
  key_usage               = "ENCRYPT_DECRYPT"
  # deletion_window_in_days = 0
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "KeyForEncryptingDecryptingOurSecretsFiles"
    Statement = [
      {
        Sid    = "Enable IAM policies"
        Effect = "Allow"
        Principal = {
          "AWS" = "arn:aws:iam::${var.environment.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow access for Administrators"
        Effect = "Allow"
        Principal = {
          "AWS" = [
            aws_iam_role.admin.arn
          ]
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "${var.environment.resource_name_prefix}-kms-secrets"
    Application = "Key for encrypting/decrypting our Secrets files"
  })
}
resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.environment.resource_name_prefix}-kms-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}