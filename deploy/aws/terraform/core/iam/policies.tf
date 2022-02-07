# ---------------------------------------------------------------------------------------------------------------------
# Policy : ReadOnly
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "read-only" {
  name        = "${var.environment.resource_name_prefix}-read-only"
  description = "Readonly access to primary AWS services (EC2, VPC, S3, RDS, CloudWatch)"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "elasticloadbalancing:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "autoscaling:Describe*",
      "Resource": "*"
    },

    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:List*",
        "cloudwatch:Describe*",
        "cloudwatch:Get*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:List*",
        "logs:Describe*",
        "logs:DescribeLogGroups",
        "logs:Get*"
      ],
      "Resource": "*"
    },
    {
        "Sid": "S3allowReadOfAllBucketsObjects",
        "Effect": "Allow",
        "Action": [
            "s3:List*",
            "s3:GetObject*",
            "s3:HeadObject"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}
