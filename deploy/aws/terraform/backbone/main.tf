terraform {
  backend "s3" {
    # Note cannot use variables here (e.g. "${var.org_short_name}") so need to hard-code (ugly)
    # bucket        = "${module.global_variables.org_domain_name}-${module.global_variables.org_short_name}-terraform-state-backbone"
    bucket         = "parkrunpointsleague.org-prpl-backbone-terraform-state" # This S3 bucket is provisioned in our bootstrap module
    encrypt        = true
    key            = "terraform.tfstate"
    dynamodb_table = "prpl-backbone-terraform-state-locking" # This DynamoDB table is provisioned in our bootstrap module
    region         = "eu-west-1"                             # Note cannot use variables here (e.g. "${var.aws_region}") so need to hard-code (ugly)
    /*
     * No need for assume_role with backbone since intended for the AWS root account
     *
      # Backbone may be in the AWS Master account or possibly within the Core account
      #  Currently use Core account for backbone since nothing currently of significance in backbone
      role_arn     = "arn:aws:iam::597767386394:role/OrganizationAccountAccessRole"
      # profile     = "prpl-core"
    */
  }
}

module "global_variables" {
  source = "../local-modules/global-variables"
}

provider "aws" {
  region = module.global_variables.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# Set Access Policy on our remote state bucket to Admins Only
#  (cause it could contain passwords or other sensitive info)
# ---------------------------------------------------------------------------------------------------------------------
data "aws_s3_bucket" "terraform-state-environment" {
  bucket = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-terraform-state"
}
# Unlike with Organization Member Accounts, Backbone is in the Master account and IAM is different in here.
# We do not use a role to identify permission to use a bucket since no switch-role in use here.
# Instead use users of prpl-admin group to identify admins
data "aws_iam_group" "admin-group" {
  group_name = "${module.global_variables.org_short_name}-admin"
}
# Allow prpl-admin group users and Root user from root "backbone" account id
module "iam-s3-bucket-policy" {
  source = "git@github.com:davidcallen/terraform-module-iam-s3-bucket-policy-for-users.git?ref=1.0.0"
  # source = "../../../../terraform-modules/terraform-module-iam-s3-bucket-policy-for-users"
  bucket_name = data.aws_s3_bucket.terraform-state-environment.bucket
  sub_policies = [
    {
      description      = "Restrict access to our terraform-state bucket to Admins"
      actions          = ["s3:*"]
      bucket_paths     = ["", "/*"]
      allowed_user_ids = data.aws_iam_group.admin-group.users[*].user_id
    }
  ]
  root_account_id     = module.global_variables.backbone_account_id
  global_default_tags = module.global_variables.default_tags
}

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
