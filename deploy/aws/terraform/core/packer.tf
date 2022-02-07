module "iam-packer-build" {
  # source = "git@github.com:davidcallen/terraform-module-iam-packer-build.git?ref=1.0.0"
  source                      = "../../../../../terraform-modules/terraform-module-iam-packer-build"
  environment                 = var.environment
  packer_s3_bucket_name       = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-packer-files"
  packer_s3_bucket_account_id = var.environment.account_id
  global_default_tags         = module.global_variables.default_tags
}

module "packer" {
  source                           = "./packer"
  backbone_account_id              = module.global_variables.backbone_account_id
  environment                      = var.environment
  org_domain_name                  = module.global_variables.org_domain_name
  org_name                         = module.global_variables.org_name
  org_short_name                   = module.global_variables.org_short_name
  share_amis_with_accounts         = var.share_amis_with_accounts
  share_amis_with_asgs_in_accounts = var.share_amis_with_asgs_in_accounts
  packer_builder_account_ids       = var.packer_builder_account_ids

  vpc_id = module.vpc.vpc_id

  allowed_ingress_cidrs_ssh = concat([var.vpc.cidr_block],
    [module.global_variables.backbone_vpc_cidrs.cidr_block],
    module.global_variables.allowed_org_private_network_cidrs,
    module.global_variables.allowed_org_vpn_cidrs
  )
  allowed_ingress_cidrs_rdp = concat([var.vpc.cidr_block],
    [module.global_variables.backbone_vpc_cidrs.cidr_block],
    module.global_variables.allowed_org_private_network_cidrs,
    module.global_variables.allowed_org_vpn_cidrs
  )
  allowed_ingress_cidrs_winrm = concat([var.vpc.cidr_block],
    [module.global_variables.backbone_vpc_cidrs.cidr_block],
    module.global_variables.allowed_org_private_network_cidrs,
    module.global_variables.allowed_org_vpn_cidrs
  )
  global_default_tags = module.global_variables.default_tags
}
