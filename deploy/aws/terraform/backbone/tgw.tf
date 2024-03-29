#  TGW has auto-accept attachments to facilitate automation.
resource "aws_ec2_transit_gateway" "tgw" {
  count                           = (var.backbone_only_account_mode == false) ? 1 : 0
  description                     = "TGW for ${module.global_variables.org_domain_name}"
  amazon_side_asn                 = "64520"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  tags = merge(module.global_variables.default_tags, {
    Name = "${var.environment.resource_name_prefix}-tgw"
  })
}
# Share above TGW into our other accounts
# This module should be applied in the account where the TGW exists (in master since TGW is currently regional only)
module "tgw-sharing-cross-accounts" {
  count = (var.backbone_only_account_mode == false) ? 1 : 0
  # source = "git@github.com:davidcallen/terraform-module-tgw-sharing-cross-accounts.git?ref=1.0.0"
  source                 = "../../../../../terraform-modules/terraform-module-tgw-sharing-cross-accounts"
  resource_name_prefix   = "${var.environment.resource_name_prefix}-tgw-share"
  tgw_arn                = aws_ec2_transit_gateway.tgw[0].arn
  share_with_account_ids = var.cross_account_access.accounts[*].account_id
  default_tags           = merge(module.global_variables.default_tags, var.environment.default_tags)
}