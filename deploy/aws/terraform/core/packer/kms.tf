# ---------------------------------------------------------------------------------------------------------------------
# KMS Customer Managed CMK Key for encrypting our packer built AMI.
#
# It needs to be a Customer Managed CMK (not AWS Managed Key) in order for the AMI to be shared with other accounts.
#   https://aws.amazon.com/blogs/security/how-to-share-encrypted-amis-across-accounts-to-launch-encrypted-ec2-instances/
#
# Additionally to share the encrypted AMIs with Service-Linked roles, such as on AutoScalingGroup in
# other accounts need to give them permission to the Key :
#   https://docs.aws.amazon.com/autoscaling/plans/userguide/aws-auto-scaling-service-linked-roles.html
#   https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-service-linked-role.html#create-service-linked-role-manual
#   https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "packer-ami-encrypting" {
  description             = "${var.environment.resource_name_prefix}-kms-ami"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 30
  policy = jsonencode({
    Version       = "2012-10-17"
    Id            = "key-default-1"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.environment.account_id}:root"
          ]
        }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow other accounts to use Key for encrypt/decrypt"
        Effect    = "Allow"
        Principal = {
          AWS = [
            for share_amis_with_account in var.share_amis_with_accounts : "arn:aws:iam::${share_amis_with_account.account_id}:root"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ListGrants",
          "kms:CreateGrant",
          "kms:RevokeGrant",
          "kms:RetireGrant"
        ]
        Resource  = "*"
      },
      {
        Sid       = "Allow service-linked role use of the CMK"
        Effect    = "Allow"
        Principal = {
          AWS = [
            # We can only share with accounts that have the AWSServiceRoleForAutoScaling service-linked role.
            # This role is created on-demand when ASG used for 1st time, so may not exist in some accounts like Customer Core accounts.
            for share_amis_with_asgs_in_account in var.share_amis_with_asgs_in_accounts : "arn:aws:iam::${share_amis_with_asgs_in_account.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource  = "*"
      },
      {
        Sid       = "Allow attachment of persistent resources"
        Effect    = "Allow"
        Principal = {
          AWS = [
            # We can only share with accounts that have the AWSServiceRoleForAutoScaling service-linked role.
            # This role is created on-demand when ASG used for 1st time, so may not exist in some accounts like Customer Core accounts.
            for share_amis_with_asgs_in_account in var.share_amis_with_asgs_in_accounts : "arn:aws:iam::${share_amis_with_asgs_in_account.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        }
        Action = [
          "kms:CreateGrant"
        ]
        Resource  = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource": "true"
          }
        }
      }
    ]
  })
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-kms-ami"
    Application     = "AMI Encryption that is shareable with other accounts"
  })
}
resource "aws_kms_alias" "packer-ami-encrypting" {
  name          = "alias/${var.environment.resource_name_prefix}-kms-ami"
  target_key_id = aws_kms_key.packer-ami-encrypting.key_id
}