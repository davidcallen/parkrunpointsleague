module "iam" {
  source              = "./iam"

  environment = {
    name                          = var.environment.name
    account_id                    = var.environment.account_id
    resource_name_prefix          = module.global_variables.org_short_name
    resource_deletion_protection  = var.environment.resource_deletion_protection
    default_tags                  = var.environment.default_tags
  }
  global_default_tags = module.global_variables.default_tags
}