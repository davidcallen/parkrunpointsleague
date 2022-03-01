# ---------------------------------------------------------------------------------------------------------------------
# Role : Admin
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "admin" {
  name        = "${var.environment.resource_name_prefix}-admin"
  max_session_duration = 43200

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${module.global_variables.backbone_account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {"aws:MultiFactorAuthPresent": "true"}
      }
    }
  ]
}
EOF

  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-admin"
  })
}

resource "aws_iam_role_policy_attachment" "admin_admin" {
  role       = aws_iam_role.admin.name
  policy_arn = aws_iam_policy.admin.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Admin
#   TODO : limit admin access to used AWS services only ?
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "admin" {
  name        = "${var.environment.resource_name_prefix}-admin"
  description = "Admin access to all AWS services"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "NotAction": [
                "aws-portal:*",
                "budgets:*",
                "cur:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

