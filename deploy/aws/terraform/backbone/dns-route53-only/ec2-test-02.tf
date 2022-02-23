# ---------------------------------------------------------------------------------------------------------------------
# An EC2 instance for testing route53
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "test-02" {
  count                = (var.route53_testing_mode_enabled) ? 1 : 0
  ami                  = data.aws_ami.centos-7.id
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
    aws_ec2_instance_name                 = "${var.environment.resource_name_prefix}-test-02"
    aws_ec2_instance_fqdn                 = "${var.environment.resource_name_prefix}-test-02.${var.environment.name}.${var.org_domain_name}"
    aws_route53_enabled                   = "TRUE"
    aws_route53_direct_dns_update_enabled = var.route53_direct_dns_update_enabled ? "TRUE" : "FALSE"
    aws_route53_private_hosted_zone_id    = aws_route53_zone.private.id
  })
  tags = merge(var.default_tags, var.environment.default_tags, {
    Name        = "${var.environment.resource_name_prefix}-test-02"
    Zone        = var.aws_zones[0]
    Visibility  = "private"
    Application = "ec2-test"
  })
}
output "ec2_test_02_ip_address" {
  value = (var.route53_testing_mode_enabled) ? aws_instance.test-02[0].private_ip : ""
}