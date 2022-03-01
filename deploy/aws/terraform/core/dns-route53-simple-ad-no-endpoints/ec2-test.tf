# ---------------------------------------------------------------------------------------------------------------------
# An EC2 instance for testing route53
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "test" {
  count                = (var.route53_testing_mode_enabled) ? 1 : 0
  ami                  = var.route53_testing_mode_ami_id
  instance_type        = "t3a.nano"
  iam_instance_profile = aws_iam_instance_profile.test[0].name
  subnet_id            = var.vpc.private_subnets_ids[0]
  # vpc_security_group_ids = local.vpc_security_group_ids
  key_name = var.ec2_ssh_key_pair_name
  root_block_device {
    delete_on_termination = true
    encrypted             = true
  }
  disable_api_termination = var.environment.resource_deletion_protection
  user_data = templatefile("${path.module}/ec2-test-user-data.yaml", {
    aws_ec2_instance_name                 = "${var.environment.resource_name_prefix}-test"
    aws_ec2_instance_fqdn                 = "${var.environment.resource_name_prefix}-test.${var.environment.name}.${var.org_domain_name}"
    aws_route53_enabled                   = "TRUE"
    aws_route53_direct_dns_update_enabled = var.route53_direct_dns_update_enabled ? "TRUE" : "FALSE"
    aws_route53_private_hosted_zone_id    = aws_route53_zone.private.id
  })
  tags = merge(var.default_tags, var.environment.default_tags, {
    Name        = "${var.environment.resource_name_prefix}-test"
    Zone        = var.aws_zones[0]
    Visibility  = "private"
    Application = "test"
  })
}
output "ec2_test_ip_address" {
  value = (var.route53_testing_mode_enabled) ? aws_instance.test[0].private_ip : ""
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for use by an EC2 instance
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "test" {
  count                = (var.route53_testing_mode_enabled) ? 1 : 0
  name                 = "${var.environment.resource_name_prefix}-test"
  max_session_duration = 43200
  assume_role_policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = merge(var.default_tags, var.environment.default_tags, {
    Name = "${var.environment.resource_name_prefix}-test"
  })
}

# 2) Nexus get config files from S3
resource "aws_iam_policy" "route53" {
  count       = (var.route53_testing_mode_enabled) ? 1 : 0
  name        = "${var.environment.resource_name_prefix}-test-route53"
  description = "Route53"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Route53registerDNS",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:route53:::hostedzone/${aws_route53_zone.private.id}"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "route53" {
  count      = (var.route53_testing_mode_enabled) ? 1 : 0
  role       = aws_iam_role.test[0].name
  policy_arn = aws_iam_policy.route53[0].arn
}

resource "aws_iam_instance_profile" "test" {
  count = (var.route53_testing_mode_enabled) ? 1 : 0
  name  = "test"
  role  = aws_iam_role.test[0].name
}