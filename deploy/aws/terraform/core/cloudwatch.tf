module "cloudwatch-logs-windows" {
  # source      = "git@github.com:davidcallen/terraform-module-aws-cloudwatch-logs-windows.git?ref=1.0.0"
  source                               = "../../../../../terraform-modules/terraform-module-aws-cloudwatch-logs-windows"
  cloudwatch_log_groups_retention_days = var.environment.cloudwatch_log_groups_default_retention_days
  default_tags                         = merge(module.global_variables.default_tags, var.environment.default_tags)
}