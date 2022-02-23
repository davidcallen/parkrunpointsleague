# ---------------------------------------------------------------------------------------------------------------------
# Windows Active Directory - Admin Desktop
# ---------------------------------------------------------------------------------------------------------------------
module "simple-ad-admin-win" {
  # source              = "git@github.com:davidcallen/terraform-module-simple-ad-admin-win.git?ref=1.0.0"
  source                            = "../../../../../../terraform-modules/terraform-module-aws-simple-ad-admin-win"
  aws_region                        = var.aws_region
  aws_zones                         = var.aws_zones
  org_short_name                    = var.org_short_name
  org_domain_name                   = var.org_domain_name
  vpc_id                            = var.vpc.vpc_id
  vpc_cidr_block                    = var.vpc.cidr_block
  vpc_private_subnet_cidrs          = var.vpc.private_subnets_cidr_blocks
  vpc_private_subnet_ids            = var.vpc.private_subnets_ids
  name                              = "simple-ad-admin-win"
  resource_name_prefix              = var.environment.resource_name_prefix
  name_suffix                       = ""
  hostname_fqdn                     = "${var.environment.resource_name_prefix}-simple-ad-admin-win.${var.environment.name}.${var.org_domain_name}"
  route53_enabled                   = true
  route53_direct_dns_update_enabled = false
  route53_private_hosted_zone_id    = aws_route53_zone.private.id

  # domain_name                 = "${var.environment.name}.${var.org_domain_name}"
  domain_name                 = var.org_domain_name
  domain_netbios_name         = aws_directory_service_directory.simple-directory.short_name # upper(var.org_short_name)
  domain_join_user_name       = "Administrator"                                             # var.active_directory_domain_join_user_name
  domain_join_user_password   = var.central_directory_admin_password                        # var.active_directory_domain_join_user_password    # TODO : move to Vault
  domain_login_allowed_users  = []                                                          # ["david"]
  domain_login_allowed_groups = ["Domain Users"]                                            # ["CloudAdmins"]

  aws_zone_placement_index = 0
  # dns_ip_addresses         = aws_directory_service_directory.simple-directory.dns_ip_addresses # [var.active_directory_ip_addresses_eu-west-1[0], cidrhost(var.vpc.cidr_block, 2)]
  # dns_ip_addresses        = ["192.168.1.161", cidrhost(var.vpc.private_subnets_cidr_blocks, 2), "192.168.1.162"]
  aws_ami_id        = var.central_directory_admin_ami_id_win
  aws_instance_type = "t3a.small"
  //  static_networking = {
  //    ip_address = cidrhost(var.vpc.private_subnets_cidr_blocks[0], 6)
  //    netmask    = cidrnetmask(var.vpc.private_subnets_cidr_blocks[0])
  //    gateway    = cidrhost(var.vpc.private_subnets_cidr_blocks[0], 1)
  //  }
  aws_ssh_key_name     = var.ec2_ssh_key_pair_name
  iam_instance_profile = module.iam-simple-ad-admin.simple_ad_admin_profile.name # module.iam-cloudwatch.cloudwatch-agent-profile-name
  disk_root = {
    encrypted = true
    size      = 30
  }
  allowed_ingress_cidrs = {
    rdp = var.allowed_ingress_cidrs.rdp
    ssh = var.allowed_ingress_cidrs.ssh
  }
  allowed_egress_cidrs = {
    http              = ["0.0.0.0/0"]
    https             = ["0.0.0.0/0"]
    telegraf_influxdb = ["0.0.0.0/0"]
  }
  resource_deletion_protection = var.environment.resource_deletion_protection
  tags                         = merge(var.default_tags, var.environment.default_tags)
}
output "simple_ad_admin_win_aws_instance_private_ip" {
  value = module.simple-ad-admin-win.aws_instance_private_ip
}