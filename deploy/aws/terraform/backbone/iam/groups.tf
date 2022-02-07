# Base User Group
resource "aws_iam_group" "user" {
  name = "${var.environment.resource_name_prefix}-user"
}

# ReadOnly access to PRPL
resource "aws_iam_group" "read-only" {
  name = "${var.environment.resource_name_prefix}-read-only"
}

# Dev (including QA is also currently in this group)
resource "aws_iam_group" "development" {
  name = "${var.environment.resource_name_prefix}-development"
}

resource "aws_iam_group" "business-analysis" {
  name = "${var.environment.resource_name_prefix}-business-analysis"
}

resource "aws_iam_group" "billing-read-only" {
  name = "${var.environment.resource_name_prefix}-billing-read-only"
}

resource "aws_iam_group" "billing" {
  name = "${var.environment.resource_name_prefix}-billing"
}

resource "aws_iam_group" "support-read-only" {
  name = "${var.environment.resource_name_prefix}-support-read-only"
}

resource "aws_iam_group" "support" {
  name = "${var.environment.resource_name_prefix}-support"
}

resource "aws_iam_group" "support-prod" {
  name = "${var.environment.resource_name_prefix}-support-prod"
}

resource "aws_iam_group" "management" {
  name = "${var.environment.resource_name_prefix}-management"
}

resource "aws_iam_group" "admin-read-only" {
  name = "${var.environment.resource_name_prefix}-admin-read-only"
}

// Moved into Bootstrap
//resource "aws_iam_group" "admin" {
//  name = "${var.environment.resource_name_prefix}-admin"
//}
data "aws_iam_group" "admin" {
  group_name = "${var.environment.resource_name_prefix}-admin"
}

resource "aws_iam_group" "super-admin" {
  name = "${var.environment.resource_name_prefix}-super-admin"
}

resource "aws_iam_group" "security-audit" {
  name = "${var.environment.resource_name_prefix}-security-audit"
}

resource "aws_iam_group" "aws-support" {
  name = "${var.environment.resource_name_prefix}-aws-support"
}
