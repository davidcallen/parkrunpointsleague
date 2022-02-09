# ---------------------------------------------------------------------------------------------------------------------
# Terraform client configuration and remote state (s3 bucket)
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "s3" {
    # Note cannot use variables here (e.g. "${var.org_short_name}") so need to hard-code (ugly)
    #bucket         = "${module.global_variables.org_domain_name}-${module.global_variables.org_short_name}-terraform-state-core"
    bucket         = "parkrunpointsleague.org-prpl-core-terraform-state" # This S3 bucket is provisioned in our bootstrap module
    encrypt        = true
    key            = "terraform.tfstate"
    dynamodb_table = "prpl-core-terraform-state-locking" # This DynamoDB table is provisioned in our bootstrap module
    region         = "eu-west-1"                         # Note cannot use variables here (e.g. "${var.aws_region}") so need to hard-code (ugly)
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Import modules
# ---------------------------------------------------------------------------------------------------------------------
module "global_variables" {
  source = "../local-modules/global-variables"
}

# ---------------------------------------------------------------------------------------------------------------------
# Configure the AWS Provider
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = module.global_variables.aws_region
}
//
//# ---------------------------------------------------------------------------------------------------------------------
//# Get backbone remote state to access its output variables
//# ---------------------------------------------------------------------------------------------------------------------
//data "terraform_remote_state" "backbone" {
//  backend = "s3"
//  config = {
//    bucket      = "${module.global_variables.org_domain_name}-prpl-backbone-terraform-state"
//    key         = "terraform.tfstate"
//    region      = module.global_variables.aws_region
//
//    # NO NEED to use role since backbone is not in Core account but in AWS Root account and
//    #   that is the account we are running terraform against (hence empty profile)
//    # The role_arn is needed to perform terraform into a cross-account
//    # role_arn    = "arn:aws:iam::${module.global_variables.backbone_account_id}:role/prpl-backbone-admin"
//  }
//}

# ---------------------------------------------------------------------------------------------------------------------
# Create ssh_key_pair and upload ssh public key from file to there
#   Requires an ssh key to already exist that was created like "ssh-keygen -f ~/.ssh/prpl-aws/prpl-foobar-ssh-key -t rsa -b 2048 -m pem"
# ---------------------------------------------------------------------------------------------------------------------
data "tls_public_key" "ssh-key" {
  private_key_pem = file("~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key")
}
resource "aws_key_pair" "ssh" {
  key_name   = "${var.environment.resource_name_prefix}-ssh-key"
  public_key = data.tls_public_key.ssh-key.public_key_openssh
}

data "aws_caller_identity" "current" {}
