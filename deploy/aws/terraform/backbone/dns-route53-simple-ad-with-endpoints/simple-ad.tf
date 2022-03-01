resource "aws_directory_service_directory" "simple-directory" {
  name       = var.org_domain_name
  short_name = upper(var.org_short_name)
  alias      = var.org_short_name
  enable_sso = false
  type     = "SimpleAD"
  password = var.central_directory_admin_password
  size     = "Small"
  vpc_settings {
    vpc_id     = var.vpc.vpc_id
    subnet_ids = var.vpc.private_subnets_ids
  }
  tags = merge(var.default_tags, var.environment.default_tags)
}
# Output our above SimpleAD IPs so this can be read by the cross-accounts terraform for firewall access to it.
# Note: this could also be achieved by reading terraform state files but then get caught in a catch-22 circular-dependancy hell.
resource "local_file" "central_directory_dns_ips" {
  #  count                = (var.route53_enabled) ? 1 : 0
  content              = join(",", aws_directory_service_directory.simple-directory.dns_ip_addresses)
  directory_permission = "660"
  file_permission      = "660"
  filename             = "${path.module}/../outputs/terraform-output-central-directory-dns-ips"
}
//# ---------------------------------------------------------------------------------------------------------------------
//# DNS / Route53
//# ---------------------------------------------------------------------------------------------------------------------
//# Instead of point to SimpleAD DNS, use a Route53 Forwarder to it. This should fix the EFS DNS resolution issue.
//resource "aws_vpc_dhcp_options" "simple-directory" {
//  domain_name         = var.org_domain_name
//  domain_name_servers = aws_directory_service_directory.simple-directory.dns_ip_addresses
//  tags                = merge(var.default_tags, var.environment.default_tags)
//}
//resource "aws_vpc_dhcp_options_association" "simple-directory" {
//  vpc_id          = var.vpc.vpc_id
//  dhcp_options_id = aws_vpc_dhcp_options.simple-directory.id
//}
//# Instead of point to SimpleAD DNS, use a Route53 Forwarder to it. This should fix the EFS DNS resolution issue.
//resource "aws_route53_resolver_rule" "simple-ad" {
//  count   = (var.route53_enabled) ? 1 : 0
//  domain_name          = "${var.environment.name}.${var.org_domain_name}"
//  name                 = var.environment.name
//  rule_type            = "FORWARD"
//  dynamic "target_ip" {
//    for_each = aws_directory_service_directory.simple-directory.dns_ip_addresses
//    content {
//      ip = target_ip.value
//    }
//  }
//  tags = merge(var.default_tags, var.environment.default_tags)
//}
//resource "aws_route53_resolver_rule_association" "simple-ad" {
//  count   = (var.route53_enabled) ? 1 : 0
//  name =  "${var.org_short_name}-route53-dns-simple-ad"
//  resolver_rule_id = aws_route53_resolver_rule.simple-ad[0].id
//  vpc_id           = var.vpc.vpc_id
//}
//# Instead of point to SimpleAD DNS, use a Route53 Forwarder to it. This should fix the EFS DNS resolution issue.
//resource "aws_route53_resolver_rule" "simple-ad-tld" {
//  count   = (var.route53_enabled) ? 1 : 0
//  domain_name          = var.org_domain_name
//  name                 = var.environment.name
//  rule_type            = "FORWARD"
//  dynamic "target_ip" {
//    for_each = aws_directory_service_directory.simple-directory.dns_ip_addresses
//    content {
//      ip = target_ip.value
//    }
//  }
//  tags = merge(var.default_tags, var.environment.default_tags)
//}
//resource "aws_route53_resolver_rule_association" "simple-ad-tld" {
//  count   = (var.route53_enabled) ? 1 : 0
//  name =  "${var.org_short_name}-route53-dns-simple-ad-tld"
//  resolver_rule_id = aws_route53_resolver_rule.simple-ad-tld[0].id
//  vpc_id           = var.vpc.vpc_id
//}

//# ---------------------------------------------------------------------------------------------------------------------
//# Cloudwatch for Logs - Log subscription only available on AWS Managed (full) AD
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_directory_service_log_subscription" "simple-directory" {
//  directory_id   = aws_directory_service_directory.simple-directory.id
//  log_group_name = aws_cloudwatch_log_group.simple-directory.name
//}

//# ---------------------------------------------------------------------------------------------------------------------
//# Secrets
//# ---------------------------------------------------------------------------------------------------------------------
//module "simple-ad-admin-password-secret" {
//  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
//  source                  = "../../../../../../terraform-modules/terraform-module-aws-asm-secret"
//  name                    = "${var.environment.resource_name_prefix}-simple-ad-admin-password"
//  description             = "SimpleAD Admin internal user login password"
//  recovery_window_in_days = 0 # Force secret deletion to action immediately
//  account_id              = var.environment.account_id
//  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State and git
//  password = var.central_directory_admin_password
//  allowed_iam_user_ids = concat(var.central_directory_admin_password_secret_allowed_iam_user_ids,
//    ["${module.iam-simple-ad-admin.simple_ad_admin_role.unique_id}:*"]
//  )
//}
# ---------------------------------------------------------------------------------------------------------------------
# A Security Group for use by linux ec2 instance to join and communicate with an AD domain
# ---------------------------------------------------------------------------------------------------------------------
locals {
  #ad_ip_cidrs = [for ip in var.active_directory_ip_addresses_eu-west-1 : "${ip}/32"]
  ad_ip_cidrs = [for ip in aws_directory_service_directory.simple-directory.dns_ip_addresses : "${ip}/32"]
}
module "ad-security-group-for-linux" {
  # source              = "git@github.com:davidcallen/terraform-module-aws-active-directory-security-group-for-linux.git?ref=1.0.0"
  source = "../../../../../../terraform-modules/terraform-module-aws-active-directory-security-group-for-linux"

  environment = {
    resource_name_prefix = var.environment.resource_name_prefix
    default_tags         = var.environment.default_tags
  }
  vpc = {
    vpc_id                      = var.vpc.vpc_id
    cidr_block                  = var.vpc.cidr_block
    private_subnets_cidr_blocks = var.vpc.private_subnets_cidr_blocks
    private_subnets_ids         = var.vpc.private_subnets_ids
    public_subnets_cidr_blocks  = var.vpc.private_subnets_cidr_blocks
    public_subnets_ids          = var.vpc.public_subnets_ids
  }
  name        = "ad-for-linux"
  ad_ip_cidrs = local.ad_ip_cidrs # "${var.eu-west-1_active_directory_ip_addresses[*]}/32"
}
output "central_directory_dns_server_ips" {
  value = aws_directory_service_directory.simple-directory.dns_ip_addresses
}