module "iam" {
  source              = "./iam"
  environment         = var.environment
  backbone_account_id = module.global_variables.backbone_account_id
  global_default_tags = module.global_variables.default_tags
}

//module "iam-cloudwatch" {
//  # source          = "git@github.com:davidcallen/terraform-module-iam-cloudwatch.git?ref=1.0.0"
//  source              = "../../local-modules/iam-cloudwatch"
//  environment         = var.environment
//  global_default_tags = module.global_variables.default_tags
//}

data "aws_iam_role" "admin" {
  name = "${var.environment.resource_name_prefix}-admin"
}
data "aws_iam_role" "OrganizationAccountAccessRole" {
  name = "OrganizationAccountAccessRole"
}