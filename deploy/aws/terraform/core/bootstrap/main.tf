module "global_variables" {
  source = "../../local-modules/global-variables"
}

# Configure the AWS Provider
provider "aws" {
  region = module.global_variables.aws_region
}

data "aws_caller_identity" "current" {}
