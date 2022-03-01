# ---------------------------------------------------------------------------------------------------------------------
# Route53 Only (no central directory).
# Uses Endpoints for cross-account resolution and on-premise resolution.
# Requires :
#   - two or more subnets
#   - route53_enabled = true
# ---------------------------------------------------------------------------------------------------------------------
module "dns" {
  count                              = (module.global_variables.route53_enabled) ? 1 : 0
  source                             = "./dns-route53-only"
  aws_region                         = module.global_variables.aws_region
  aws_zones                          = module.global_variables.aws_zones
  aws_zone_preferred_placement_index = module.global_variables.aws_zone_preferred_placement_index
  org_domain_name                    = module.global_variables.org_domain_name
  org_using_subdomains               = module.global_variables.org_using_subdomains
  org_short_name                     = module.global_variables.org_short_name
  on_premise_domain_name             = module.global_variables.on_premise_domain_name
  on_premise_dns_server_ips          = module.global_variables.on_premise_dns_server_ips
  route53_use_endpoints              = module.global_variables.route53_use_endpoints
  route53_testing_mode_enabled       = var.route53_testing_mode_enabled
  route53_testing_mode_ami_id        = data.aws_ami.centos-7-base.id
  route53_direct_dns_update_enabled  = module.global_variables.route53_direct_dns_update_enabled
  environment                        = var.environment
  vpc = {
    vpc_id                      = module.vpc.vpc_id
    cidr_block                  = module.vpc.vpc_cidr_block
    private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
    private_subnets_ids         = module.vpc.private_subnets
    public_subnets_cidr_blocks  = module.vpc.private_subnets_cidr_blocks
    public_subnets_ids          = module.vpc.public_subnets
  }
  share_with_account_ids = var.cross_account_access.accounts[*].account_id
  route53_endpoint_inbound_allow_ingress_cidrs = concat(
    [var.vpc.cidr_block],
    var.cross_account_access.accounts[*].cidr_block,
    module.global_variables.allowed_org_vpn_cidrs
  )
  route53_endpoint_inbound_allow_egress_cidrs = concat(
    [var.vpc.cidr_block],
    var.cross_account_access.accounts[*].cidr_block,
    module.global_variables.allowed_org_vpn_cidrs
  )
  route53_endpoint_outbound_allow_ingress_cidrs = concat(
    [var.vpc.cidr_block],
    var.cross_account_access.accounts[*].cidr_block
  )
  route53_endpoint_outbound_allow_egress_cidrs = concat(
    [var.vpc.cidr_block],
    var.cross_account_access.accounts[*].cidr_block,
    module.global_variables.allowed_org_vpn_cidrs
  )
  ec2_ssh_key_pair_name = aws_key_pair.ssh.key_name
  default_tags          = module.global_variables.default_tags
}
output "route53_private_hosted_zone_id" {
  value = module.dns[0].route53_private_hosted_zone_id
}
//
//# ---------------------------------------------------------------------------------------------------------------------
//# Route53 with Central Directory (SimpleAD)
//# SimpleAD is in Core
//# Not currently Uses Endpoints for cross-account resolution and on-premise resolution.
//# Requires :
//#   - one or more subnets
//#   - route53_enabled = true
//#   - central_directory_enabled = true
//# ---------------------------------------------------------------------------------------------------------------------
//module "dns" {
//  count                              = (module.global_variables.route53_enabled) ? 1 : 0
//  source                             = "./dns-route53-simple-ad-no-endpoints"
//  aws_region                         = module.global_variables.aws_region
//  aws_zones                          = module.global_variables.aws_zones
//  aws_zone_preferred_placement_index = module.global_variables.aws_zone_preferred_placement_index
//  org_domain_name                    = module.global_variables.org_domain_name
//  org_using_subdomains               = module.global_variables.org_using_subdomains
//  org_short_name                     = module.global_variables.org_short_name
//  on_premise_domain_name             = module.global_variables.on_premise_domain_name
//  on_premise_dns_server_ips          = module.global_variables.on_premise_dns_server_ips
//  route53_use_endpoints              = module.global_variables.route53_use_endpoints
//  route53_testing_mode_enabled       = var.route53_testing_mode_enabled
//  route53_testing_mode_ami_id        = data.aws_ami.centos-7-base.id
//  route53_direct_dns_update_enabled  = module.global_variables.route53_direct_dns_update_enabled
//  environment                        = var.environment
//  vpc = {
//    vpc_id                      = module.vpc.vpc_id
//    cidr_block                  = module.vpc.vpc_cidr_block
//    private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
//    private_subnets_ids         = module.vpc.private_subnets
//    public_subnets_cidr_blocks  = module.vpc.private_subnets_cidr_blocks
//    public_subnets_ids          = module.vpc.public_subnets
//  }
//  share_with_account_ids           = [] # var.cross_account_access.accounts[*].account_id
//  central_directory_admin_password = local.secrets_primary.data["ad-admin.password"]
//  central_directory_admin_password_secret_allowed_iam_user_ids = [
//    var.environment.account_id,
//    "${data.aws_iam_role.admin.unique_id}:*",
//    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*"
//  ]
//  central_directory_admin_ami_id_linux = data.aws_ami.centos-7-base.id
//  central_directory_admin_ami_id_win   = data.aws_ami.win-2019-base[0].id
//  route53_endpoint_inbound_allow_ingress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  route53_endpoint_inbound_allow_egress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  route53_endpoint_outbound_allow_ingress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block
//  )
//  route53_endpoint_outbound_allow_egress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  ec2_ssh_key_pair_name = aws_key_pair.ssh.key_name
//  allowed_ingress_cidrs = {
//    rdp = concat(
//      [module.vpc.vpc_cidr_block],
//      module.global_variables.allowed_org_private_network_cidrs,
//      var.cross_account_access.accounts[*].cidr_block
//    )
//    ssh = concat(
//      [module.vpc.vpc_cidr_block],
//      module.global_variables.allowed_org_private_network_cidrs,
//      var.cross_account_access.accounts[*].cidr_block
//    )
//  }
//  telegraf_enabled                   = module.global_variables.telegraf_enabled
//  telegraf_influxdb_cidr             = module.global_variables.telegraf_influxdb_cidr
//  telegraf_influxdb_retention_policy = module.global_variables.telegraf_influxdb_retention_policy
//  telegraf_influxdb_url              = module.global_variables.telegraf_influxdb_url
//  default_tags                       = module.global_variables.default_tags
//}
//output "route53_private_hosted_zone_id" {
//  value = module.dns[0].route53_private_hosted_zone_id
//}
//output "central_directory_dns_server_ips" {
//  value = module.dns[0].central_directory_dns_server_ips
//}
//output "simple_ad_admin_linux_aws_instance_private_ip" {
//  value = module.dns[0].simple_ad_admin_linux_aws_instance_private_ip
//}
//output "simple_ad_admin_win_aws_instance_private_ip" {
//  value = module.dns[0].simple_ad_admin_win_aws_instance_private_ip
//}


# ---------------------------------------------------------------------------------------------------------------------
# Route53 with Central Directory (SimpleAD) and Endpoints.
# SimpleAD is in Backbone
# Uses Endpoints for cross-account resolution and on-premise resolution.
# Requires :
#   - one or more subnets
#   - route53_enabled = true
#   - central_directory_enabled = true
# ---------------------------------------------------------------------------------------------------------------------
//module "dns" {
//  count                              = (module.global_variables.route53_enabled) ? 1 : 0
//  source                             = "./dns-route53-simple-ad-with-endpoints"
//  aws_region                         = module.global_variables.aws_region
//  aws_zones                          = module.global_variables.aws_zones
//  aws_zone_preferred_placement_index = module.global_variables.aws_zone_preferred_placement_index
//  org_domain_name                    = module.global_variables.org_domain_name
//  org_using_subdomains               = module.global_variables.org_using_subdomains
//  org_short_name                     = module.global_variables.org_short_name
//  on_premise_domain_name             = module.global_variables.on_premise_domain_name
//  on_premise_dns_server_ips          = module.global_variables.on_premise_dns_server_ips
//  route53_use_endpoints              = module.global_variables.route53_use_endpoints
//  route53_testing_mode_enabled       = var.route53_testing_mode_enabled
//  route53_testing_mode_ami_id        = data.aws_ami.centos-7-base.id
//  route53_direct_dns_update_enabled  = module.global_variables.route53_direct_dns_update_enabled
//  environment                        = var.environment
//  vpc = {
//    vpc_id                      = module.vpc.vpc_id
//    cidr_block                  = module.vpc.vpc_cidr_block
//    private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
//    private_subnets_ids         = module.vpc.private_subnets
//    public_subnets_cidr_blocks  = module.vpc.private_subnets_cidr_blocks
//    public_subnets_ids          = module.vpc.public_subnets
//  }
//  share_with_account_ids           = [] # var.cross_account_access.accounts[*].account_id
//  central_directory_admin_password = local.secrets_primary.data["ad-admin.password"]
//  central_directory_admin_password_secret_allowed_iam_user_ids = [
//    var.environment.account_id,
//    "${data.aws_iam_role.admin.unique_id}:*",
//    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*"
//  ]
//  central_directory_admin_ami_id_linux = data.aws_ami.centos-7-base.id
//  central_directory_admin_ami_id_win   = data.aws_ami.win-2019-base[0].id
//  route53_endpoint_inbound_allow_ingress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  route53_endpoint_inbound_allow_egress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  route53_endpoint_outbound_allow_ingress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block
//  )
//  route53_endpoint_outbound_allow_egress_cidrs = concat(
//    [var.vpc.cidr_block],
//    var.cross_account_access.accounts[*].cidr_block,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  ec2_ssh_key_pair_name = aws_key_pair.ssh.key_name
//  allowed_ingress_cidrs = {
//    rdp = concat(
//      [module.vpc.vpc_cidr_block],
//      module.global_variables.allowed_org_private_network_cidrs,
//      var.cross_account_access.accounts[*].cidr_block
//    )
//    ssh = concat(
//      [module.vpc.vpc_cidr_block],
//      module.global_variables.allowed_org_private_network_cidrs,
//      var.cross_account_access.accounts[*].cidr_block
//    )
//  }
//  telegraf_enabled                   = module.global_variables.telegraf_enabled
//  telegraf_influxdb_cidr             = module.global_variables.telegraf_influxdb_cidr
//  telegraf_influxdb_retention_policy = module.global_variables.telegraf_influxdb_retention_policy
//  telegraf_influxdb_url              = module.global_variables.telegraf_influxdb_url
//  default_tags                       = module.global_variables.default_tags
//}
//output "route53_private_hosted_zone_id" {
//  value = module.dns[0].route53_private_hosted_zone_id
//}
//output "simple_ad_admin_linux_aws_instance_private_ip" {
//  value = module.dns[0].simple_ad_admin_linux_aws_instance_private_ip
//}
//output "simple_ad_admin_win_aws_instance_private_ip" {
//  value = module.dns[0].simple_ad_admin_win_aws_instance_private_ip
//}
