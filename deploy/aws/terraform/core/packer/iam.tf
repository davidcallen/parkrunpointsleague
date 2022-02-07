# ---------------------------------------------------------------------------------------------------------------------
# Role : Packer S3 Files
#  Method for IAM Access to Packer S3 bucket is based on article : https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html
#  Note: role is for programmatic access so MFA is not required. Set CLI max session to 8 hours so can process uninterrupted.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "packer-files-s3-read" {
  name                  = "${var.environment.resource_name_prefix}-packer-files-s3-read"
  max_session_duration  = 43200
  assume_role_policy    = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        Sid         = "AllowPackerBuildAccessS3bucketRead"
        Effect      = "Allow"
        Principal = {
          AWS = concat(
          [
            for packer_builder_account_id in sort(var.packer_builder_account_ids) : "arn:aws:iam::${packer_builder_account_id}:root"
          ],
          [
            "arn:aws:iam::${var.environment.account_id}:root",
            "arn:aws:iam::${var.backbone_account_id}:root"
          ]
          )
        }
        Action      = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-packer-files-s3-read"
    Description     = "Allow Packer building accounts to assume this role to access packer s3 bucket to get software installers"
  })
}

resource "aws_iam_role_policy_attachment" "packer-files-s3-read_packer-files-s3-read" {
  role       = aws_iam_role.packer-files-s3-read.name
  policy_arn = aws_iam_policy.packer-files-s3-read.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Packer files in S3 with Read access
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "packer-files-s3-read" {
  name        = "${var.environment.resource_name_prefix}-packer-files-s3-read"
  description = "Read access to Packer files S3 bucket (for software installers etc..)"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3allowReadOfBucketObjects",
      "Effect": "Allow",
      "Action": [
          "s3:List*",
          "s3:GetObject*",
          "s3:HeadObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.org_domain_name}-${var.environment.resource_name_prefix}-packer-files",
        "arn:aws:s3:::${var.org_domain_name}-${var.environment.resource_name_prefix}-packer-files/*"
      ]
    }
  ]
}
EOF
}
