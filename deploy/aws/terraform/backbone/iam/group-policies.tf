# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : User  (Base Group)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "user_mfa" {
  group      = aws_iam_group.user.name
  policy_arn = aws_iam_policy.mfa.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Read Only
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "read-only_assume-role_read-only" {
  group      = aws_iam_group.read-only.name
  policy_arn = aws_iam_policy.assume-role-read-only.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Development
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "development_assume-role_development" {
  group      = aws_iam_group.development.name
  policy_arn = aws_iam_policy.assume-role-development.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Support
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "support-read-only" {
  group      = aws_iam_group.support-read-only.name
  policy_arn = aws_iam_policy.support-read-only.arn
}

resource "aws_iam_group_policy_attachment" "support-read-only_assume-role_read-only" {
  group      = aws_iam_group.support-read-only.name
  policy_arn = aws_iam_policy.assume-role-support-read-only.arn
}

resource "aws_iam_group_policy_attachment" "support_assume-role_support" {
  group      = aws_iam_group.support.name
  policy_arn = aws_iam_policy.assume-role-support.arn
}

resource "aws_iam_group_policy_attachment" "support_assume-role_support-prod" {
  group      = aws_iam_group.support-prod.name
  policy_arn = aws_iam_policy.assume-role-support-prod.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Admin Read Only
# Note: could not limit to using Service-specific read-only managed policies since AWS limits to 10 attachments
# Instead simply used the one AWS managed policy "ReadOnlyAccess"
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "admin-read-only_assume-role_admin-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = aws_iam_policy.assume-role-admin-read-only.arn
}
resource "aws_iam_group_policy_attachment" "admin-read-only_read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
/*
resource "aws_iam_group_policy_attachment" "admin-read-only_dynamodb-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_ec2-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_efs-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_rds-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_s3-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_sns-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_vpc-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_asg-console-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingConsoleReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_asg-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_organizations-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_ram-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/AWSResourceAccessManagerReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "admin-read-only_cloudwatch-logs-read-only" {
  group      = aws_iam_group.admin-read-only.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}
*/

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Admin
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "admin_assume-role_admin" {
  group      = data.aws_iam_group.admin.group_name
  policy_arn = aws_iam_policy.assume-role-admin.arn
}

// Moved into Bootstrap
//resource "aws_iam_group_policy_attachment" "admin_admin" {
//  group      = data.aws_iam_group.admin.name
//  policy_arn = aws_iam_policy.admin.arn
//}

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Super Admin
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "admin_assume-role_super-admin" {
  group      = aws_iam_group.super-admin.name
  policy_arn = aws_iam_policy.assume-role-admin.arn
}

resource "aws_iam_group_policy_attachment" "super-admin_admin" {
  group      = aws_iam_group.super-admin.name
  policy_arn = data.aws_iam_policy.admin.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Billing
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "billing-read-only_billing-read-only" {
  group      = aws_iam_group.billing-read-only.name
  policy_arn = aws_iam_policy.billing-read-only.arn
}

resource "aws_iam_group_policy_attachment" "billing" {
  group      = aws_iam_group.billing.name
  policy_arn = aws_iam_policy.billing.arn
}

/*
 * dont think need billing access in other non-master accounts
 *
resource "aws_iam_group_policy_attachment" "billing_assume-role_billing" {
  group      = aws_iam_group.billing.name
  policy_arn = aws_iam_policy.assume-role-billing.arn
}
*/

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : Security Audit
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "security-audit_assume-role_security-audit" {
  group      = aws_iam_group.security-audit.name
  policy_arn = aws_iam_policy.assume-role-security-audit.arn
}
resource "aws_iam_group_policy_attachment" "security-audit_read-only-access" {
  group      = aws_iam_group.security-audit.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
resource "aws_iam_group_policy_attachment" "security-audit_security-audit" {
  group      = aws_iam_group.security-audit.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Policies : AWS Support                (for view/raise AWS Support Requests)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "aws-support" {
  group      = aws_iam_group.aws-support.name
  policy_arn = aws_iam_policy.aws-support.arn
}
