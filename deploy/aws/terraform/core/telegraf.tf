# TODO : make Telegraf, InfluxDB, Chronograf, Kapacitor, Grafana (TICK) ec2 instance

//# ---------------------------------------------------------------------------------------------------------------------
//# Secrets
//# ---------------------------------------------------------------------------------------------------------------------
//module "tick-admin-password-secret" {
//  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
//  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
//  name                    = "${var.environment.resource_name_prefix}-tick-admin"
//  description             = "TICK Admin internal user login password"
//  recovery_window_in_days = 0 # Force secret deletion to action immediately
//  account_id              = var.environment.account_id
//  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State
//  password = local.secrets_primary.tick-admin.password
//  allowed_iam_user_ids = [
//    var.environment.account_id,
//    "${data.aws_iam_role.admin.unique_id}:*",
//    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
//    "${module.iam-tick.tick-role.unique_id}:*"
//  ]
//}
//module "tick-telegraf-password-secret" {
//  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
//  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
//  name                    = "${var.environment.resource_name_prefix}-tick-telegraf"
//  description             = "TICK internal user 'telegraf' for stats inflow from Telegraf agents"
//  recovery_window_in_days = 0 # Force secret deletion to action immediately
//  account_id              = var.environment.account_id
//  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State
//  password = local.secrets_primary.tick-telegraf.password
//  allowed_iam_user_ids = [
//    var.environment.account_id,
//    "${data.aws_iam_role.admin.unique_id}:*",
//    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
//    "${module.iam-tick.tick-role.unique_id}:*"
//  ]
//}