# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : User (Base Group)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "user" {
  name    = aws_iam_group.user.name
  group   = aws_iam_group.user.name
  users = [
    data.aws_iam_user.david.user_name,
    data.aws_iam_user.iam-test.user_name
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Read Only
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "read-only" {
  name    = aws_iam_group.read-only.name
  group   = aws_iam_group.read-only.name
  users = [
    data.aws_iam_user.david.user_name
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Development
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "development" {
  name    = aws_iam_group.development.name
  group   = aws_iam_group.development.name
  users = [
    data.aws_iam_user.david.user_name
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Support
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "support-read-only" {
  name    = aws_iam_group.support-read-only.name
  group   = aws_iam_group.support-read-only.name
  users = []
}

resource "aws_iam_group_membership" "support" {
  name    = aws_iam_group.support.name
  group   = aws_iam_group.support.name
  users = []
}

resource "aws_iam_group_membership" "support-prod" {
  name    = aws_iam_group.support-prod.name
  group   = aws_iam_group.support-prod.name
  users = [
    data.aws_iam_user.david.user_name
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Billing
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "billing-read-only" {
  name    = aws_iam_group.billing-read-only.name
  group   = aws_iam_group.billing-read-only.name
  users = [
    data.aws_iam_user.david.user_name
  ]
}

resource "aws_iam_group_membership" "billing" {
  name    = aws_iam_group.billing.name
  group   = aws_iam_group.billing.name
  users = []
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Management
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "management" {
  name    = aws_iam_group.management.name
  group   = aws_iam_group.management.name
  users = []
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Admin Read Only  (excludes Billing)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "admin-read-only" {
  name    = aws_iam_group.admin-read-only.name
  group   = aws_iam_group.admin-read-only.name
  users = [
    data.aws_iam_user.iam-test.user_name
  ]
}

// Moved into Bootstrap
//# ---------------------------------------------------------------------------------------------------------------------
//# Group Membership : Admin  (currently excludes Billing)
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_iam_group_membership" "admin" {
//  name    = data.aws_iam_group.admin.group_name
//  group   = data.aws_iam_group.admin.group_name
//  users = [
//    data.aws_iam_user.david.user_name
//  ]
//}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Super Admin
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "super-admin" {
  name    = aws_iam_group.super-admin.name
  group   = aws_iam_group.super-admin.name
  users = [
    # data.aws_iam_user.david.user_name
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Security Audit
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "security-audit" {
  name    = aws_iam_group.security-audit.name
  group   = aws_iam_group.security-audit.name
  users = [
    # Can add external Security Audit users here when being audited
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : AWS Support Center       (for view/raise AWS Support Requests)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "aws-support" {
  name    = aws_iam_group.aws-support.name
  group   = aws_iam_group.aws-support.name
  users = []
}