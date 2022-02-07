# ---------------------------------------------------------------------------------------------------------------------
# Policy : User Multi Factor Authentication (MFA)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "mfa" {
  name        = "${var.environment.resource_name_prefix}-mfa-self-manage"
  description = "Based on AWS page entitled IAM Allows IAM Users to Self-Manage an MFA Device"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Sid": "BlockMostAccessUnlessSignedInWithMFA",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ListMFADevices",
                "iam:ListUsers",
                "iam:ListVirtualMFADevices",
                "iam:ResyncMFADevice",
                "iam:ChangePassword",
                "iam:GetAccountPasswordPolicy"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        },
        {
            "Sid": "AllowListActions",
            "Effect": "Allow",
            "Action": [
                "iam:ListUsers",
                "iam:ListVirtualMFADevices"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:ListMFADevices"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/*",
                "arn:aws:iam::*:user/$${aws:username}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToManageTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:CreateVirtualMFADevice",
                "iam:DeleteVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ResyncMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/$${aws:username}",
                "arn:aws:iam::*:user/$${aws:username}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA",
            "Effect": "Allow",
            "Action": [
                "iam:DeactivateMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/$${aws:username}",
                "arn:aws:iam::*:user/$${aws:username}"
            ],
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:ChangePassword"
            ],
            "Resource": [
                "arn:aws:iam::*:user/$${aws:username}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Read Only
# ---------------------------------------------------------------------------------------------------------------------
/*
# TODO : Should anyone have read-only in Core ? Probably only Admins in there...  Removed for the moment.
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::228947135432:role/prpl-core-read-only"
        },
*/
resource "aws_iam_policy" "assume-role-read-only" {
  name        = "${var.environment.resource_name_prefix}-assume-role-read-only"
  description = "Allow assume read-only role in other accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::760245709408:role/prpl-dev-read-only"
        }
    ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Development
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "assume-role-development" {
  name        = "${var.environment.resource_name_prefix}-assume-role-development"
  description = "Allow assume Development role in other accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::760245709408:role/prpl-dev-development"
        }
    ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Support
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "support-read-only" {
  name        = "${var.environment.resource_name_prefix}-support-read-only"
  description = "Allow Read-only Support in this account"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2AllowReadOnlyAccessVPNs",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeCustomerGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeVpnConnections",
                "ec2:DescribeVpnGateways"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudwatchAllowReadOnlyForVPNDashboard",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:List*",
                "cloudwatch:Describe*",
                "cloudwatch:Get*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "assume-role-support-read-only" {
  name        = "${var.environment.resource_name_prefix}-assume-role-support-read-only"
  description = "Allow assume Read-only Support role in Customer accounts (including Prod)"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::565838863285:role/prpl-uat-support-read-only"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::456409217779:role/prpl-staging-support"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::695477822503:role/prpl-demo-support"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::472687107726:role/prpl-prod-support-read-only"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "assume-role-support" {
  name        = "${var.environment.resource_name_prefix}-assume-role-support"
  description = "Allow assume Support role in Customer accounts (not Production accounts)"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::565838863285:role/prpl-uat-support"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::456409217779:role/prpl-staging-support"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::695477822503:role/prpl-demo-support"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "assume-role-support-prod" {
  name        = "${var.environment.resource_name_prefix}-assume-role-support-prod"
  description = "Allow assume Support role in Customer Production accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::565838863285:role/prpl-uat-support"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::456409217779:role/prpl-staging-support"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::695477822503:role/prpl-demo-support"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::472687107726:role/prpl-prod-support"
        }
    ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Billing
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "billing-read-only" {
  name        = "${var.environment.resource_name_prefix}-billing-read-only"
  description = "Allow Billing read-only access in this account"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "aws-portal:ViewAccount",
                "aws-portal:ViewBilling",
                "aws-portal:ViewUsage",
                "budgets:ViewBudget",
                "ce:ListCostCategoryDefinitions",
                "ce:DescribeCostCategoryDefinition",
                "cur:DescribeReportDefinitions",
                "pricing:DescribeServices",
                "pricing:GetAttributeValues",
                "pricing:GetProducts"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "billing" {
  name        = "${var.environment.resource_name_prefix}-billing"
  description = "Allow billing admin access in this account"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "aws-portal:*Billing",
                "aws-portal:*Usage",
                "aws-portal:*PaymentMethods",
                "budgets:ViewBudget",
                "budgets:ModifyBudget",
                "ce:*",
                "cur:*",
                "pricing:DescribeServices",
                "pricing:GetAttributeValues",
                "pricing:GetProducts"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : Security Audit
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "assume-role-security-audit" {
  name        = "${var.environment.resource_name_prefix}-assume-role-security-audit"
  description = "Allow assume Security Audit role in other accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::228947135432:role/prpl-core-security-audit"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::760245709408:role/prpl-dev-security-audit"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::565838863285:role/prpl-uat-security-audit"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::456409217779:role/prpl-staging-security-audit"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::695477822503:role/prpl-demo-security-audit"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::472687107726:role/prpl-prod-security-audit"
        }
    ]
}
EOF
}


# ---------------------------------------------------------------------------------------------------------------------
# Policy : Admin Read Only
#   Note : access is limited to used AWS services only
# ---------------------------------------------------------------------------------------------------------------------
/*
resource "aws_iam_policy" "admin-read-only" {
  name        = "${var.environment.resource_name_prefix}-admin-read-only"
  description = "Admin Read Only access to AWS services"
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
*/
resource "aws_iam_policy" "assume-role-admin-read-only" {
  name        = "${var.environment.resource_name_prefix}-assume-role-admin-read-only"
  description = "Allow assume Admin Read Only role in other accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::597767386394:role/prpl-backbone-admin-read-only"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::228947135432:role/prpl-core-admin-read-only"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::760245709408:role/prpl-dev-admin"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::565838863285:role/prpl-uat-admin-read-only"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::456409217779:role/prpl-staging-admin-read-only"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::695477822503:role/prpl-demo-admin-read-only"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::472687107726:role/prpl-prod-admin-read-only"
        }
    ]
}
EOF
}

//# ---------------------------------------------------------------------------------------------------------------------
//# Policy : Admin
//#   TODO : limit admin access to used AWS services only
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_iam_policy" "admin" {
//  name        = "${var.environment.resource_name_prefix}-admin"
//  description = "Admin access to all AWS services"
//  policy      = <<EOF
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Effect": "Allow",
//            "NotAction": [
//                "aws-portal:*",
//                "budgets:*",
//                "cur:*"
//            ],
//            "Resource": "*"
//        }
//    ]
//}
//EOF
//}
data "aws_iam_policy" "admin" {
  name        = "${var.environment.resource_name_prefix}-admin"
}


resource "aws_iam_policy" "assume-role-admin" {
  name        = "${var.environment.resource_name_prefix}-assume-role-admin"
  description = "Allow assume Admin role in other accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::597767386394:role/prpl-backbone-admin"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::228947135432:role/prpl-core-admin"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::760245709408:role/prpl-dev-admin"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::565838863285:role/prpl-uat-admin"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::456409217779:role/prpl-staging-admin"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::695477822503:role/prpl-demo-admin"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::472687107726:role/prpl-prod-admin"
        }
    ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Policy : AWS Support                (for view/raise AWS Support Requests)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "aws-support" {
  name        = "${var.environment.resource_name_prefix}-aws-support"
  description = "Full Access to AWS Support Center (for view/raise AWS Support Requests)"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "support:*",
                "trustedadvisor:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}