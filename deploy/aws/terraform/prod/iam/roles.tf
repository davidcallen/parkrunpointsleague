# ---------------------------------------------------------------------------------------------------------------------
# Role : Read-Only
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "read-only" {
  name        = "${var.environment.resource_name_prefix}-read-only"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.backbone_account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {"aws:MultiFactorAuthPresent": "true"}
      }
    }
  ]
}
EOF

  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-read-only"
  })
}

resource "aws_iam_role_policy_attachment" "read-only" {
  role       = aws_iam_role.read-only.name
  policy_arn = aws_iam_policy.read-only.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Role : Security Audit
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "security-audit" {
  name                = "${var.environment.resource_name_prefix}-security-audit"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.backbone_account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {"aws:MultiFactorAuthPresent": "true"}
      }
    }
  ]
}
EOF

  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-security-audit"
  })
}
resource "aws_iam_role_policy_attachment" "security-audit_read-only-access" {
  role       = aws_iam_role.security-audit.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "security-audit_security-audit" {
  role       = aws_iam_role.security-audit.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ---------------------------------------------------------------------------------------------------------------------
# Role : Admin ReadOnly
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "admin-read-only" {
  name        = "${var.environment.resource_name_prefix}-admin-read-only"
  max_session_duration = 43200

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.backbone_account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {"aws:MultiFactorAuthPresent": "true"}
      }
    }
  ]
}
EOF

  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-admin-read-only"
  })
}

resource "aws_iam_role_policy_attachment" "admin-read-only_read-only" {
  role       = aws_iam_role.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------------------------------------------------------------------------------------------------------------------
# Role : Super Admin (e.g. for viewing all areas of Backups)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "super-admin" {
  name        = "${var.environment.resource_name_prefix}-super-admin"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.backbone_account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {"aws:MultiFactorAuthPresent": "true"}
      }
    }
  ]
}
EOF

  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-super-admin"
  })
}

data "aws_iam_policy" "admin" {
  arn = "arn:aws:iam::${var.environment.account_id}:policy/${var.environment.resource_name_prefix}-admin"
}
resource "aws_iam_role_policy_attachment" "super-admin_admin" {
  role       = aws_iam_role.super-admin.name
  policy_arn = data.aws_iam_policy.admin.arn
}
