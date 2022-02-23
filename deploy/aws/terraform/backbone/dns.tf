# ---------------------------------------------------------------------------------------------------------------------
# Route53 Only (no central directory).
# Uses Endpoints for cross-account resolution and on-premise resolution.
# ---------------------------------------------------------------------------------------------------------------------
module "dns" {
  count                             = (module.global_variables.route53_enabled) ? 1 : 0
  source                            = "./dns-route53-only"
  aws_zones                         = module.global_variables.aws_zones
  org_domain_name                   = module.global_variables.org_domain_name
  org_short_name                    = module.global_variables.org_short_name
  on_premise_domain_name            = module.global_variables.on_premise_domain_name
  on_premise_dns_server_ips         = module.global_variables.on_premise_dns_server_ips
  route53_use_endpoints             = module.global_variables.route53_use_endpoints
  route53_testing_mode_enabled      = var.route53_testing_mode_enabled
  route53_direct_dns_update_enabled = module.global_variables.route53_direct_dns_update_enabled
  environment                       = var.environment
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
output "route53_endpoint_inbound_ips" {
  value = module.dns[0].route53_endpoint_inbound_ips
}
output "route53_endpoint_outbound_ips" {
  value = module.dns[0].route53_endpoint_outbound_ips
}
output "route53_ec2_test_ip_address" {
  value = module.dns[0].ec2_test_ip_address
}
output "route53_ec2_test_02_ip_address" {
  value = module.dns[0].ec2_test_02_ip_address
}