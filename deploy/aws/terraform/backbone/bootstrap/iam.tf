# ---------------------------------------------------------------------------------------------------------------------
# Essential IAM only
#   Currently used to apply to terraform state s3 bucket to limit access to admins
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_group" "admin" {
  name = "${module.global_variables.org_short_name}-admin"
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Admin
#   TODO : limit admin access to used AWS services only
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "admin" {
  name        = "${module.global_variables.org_short_name}-admin"
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

resource "aws_iam_group_policy_attachment" "admin_admin" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.admin.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Membership : Admin  (currently excludes Billing)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_group_membership" "admin" {
  name    = aws_iam_group.admin.name
  group   = aws_iam_group.admin.name
  users = [
    data.aws_iam_user.david.user_name
    # data.aws_iam_user.iam-test.user_name
  ]
}
data "aws_iam_user" "david" {
  user_name = "david"
}
//data "aws_iam_user" "iam-test" {
//  user_name = "iam-test"
//}
