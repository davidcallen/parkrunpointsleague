module "global_variables" {
  source = "../../local-modules/global-variables"
}

provider "aws" {
  region  = module.global_variables.aws_region
}

# Enable sharing of resources within our AWS Organisation (via AWS RAM)
# Need to use null_resource since no support in terraform-provider-aws for this feature - must use AWS CLI directly.
resource "null_resource" "ram" {
  provisioner "local-exec" {
    command = "aws ram enable-sharing-with-aws-organization"
  }
  triggers = {
    always_run = timestamp()
  }
}

data "aws_caller_identity" "current" {}