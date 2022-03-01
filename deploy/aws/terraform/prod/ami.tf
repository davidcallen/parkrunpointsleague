# Grant all our ASGs in this account to access the CMK in Core account so can decrypt AMI
// Can un-comment the below once ASG deployed for first time in this account :
//resource "aws_kms_grant" "asg-grant-cmk-prpl-core-kms-ami" {
//  name              = "${var.environment.resource_name_prefix}-asg-grant-cmk-prpl-core-kms-ami"
//  key_id            = "arn:aws:kms:${module.global_variables.aws_region}:${module.global_variables.core_account_id}:key/${var.amis.owner_account_kms_key_id}"
//  grantee_principal = "arn:aws:iam::${var.environment.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
//  operations        = [
//    "Encrypt",
//    "Decrypt",
//    "ReEncryptFrom",
//    "ReEncryptTo",
//    "GenerateDataKey",
//    "GenerateDataKeyWithoutPlaintext",
//    "DescribeKey",
//    "CreateGrant"
//  ]
//}

# ---------------------------------------------------------------------------------------------------------------------
# Get AMI Ids for use in our terraforming
# ---------------------------------------------------------------------------------------------------------------------
locals {
  ami_owner_centos_org = "679593333241"
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for vanilla CentOS 6 from CentOS.org
#   For filter see https://wiki.centos.org/Cloud/AWS#Finding_AMI_ids
#   aws --region eu-west-1 ec2 describe-images --owners aws-marketplace --filters Name=product-code,Values=6x5jmcajty9edm3f211pqjfn2
# Note : this AMI can be used for t2 (and other instance types) but not t3 or t3a.
#         See https://aws.amazon.com/marketplace/server/procurement?productId=74e73035-3435-48d6-88e0-89cc02ad83ee
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "centos-6" {
  most_recent = true
  filter {
    name   = "product-code"
    values = ["6x5jmcajty9edm3f211pqjfn2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [local.ami_owner_centos_org]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for vanilla CentOS 7 from CentOs.org
#   For filter see https://wiki.centos.org/Cloud/AWS#Finding_AMI_ids
#   aws --region eu-west-1 ec2 describe-images --owners aws-marketplace --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "centos-7" {
  most_recent = true
  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [local.ami_owner_centos_org]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our CentOS 6 base (inherit from vanilla CentOS 6 with yum updated, OS hardening, installs (diagnostic tools, CloudWatchAgent, Telegraf)
# Note : this AMI can be used for t2 (and other instance types) but not t3 or t3a. See https://aws.amazon.com/marketplace/server/procurement?productId=74e73035-3435-48d6-88e0-89cc02ad83ee
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=product-code,Values=6x5jmcajty9edm3f211pqjfn2 --filters Name=name,Values=prpl-centos-6-base-*
data "aws_ami" "centos-6-base" {
  count       = var.amis.centos6_base.enabled ? 1 : 0
  most_recent = true
  filter {
    name   = "product-code"
    values = ["6x5jmcajty9edm3f211pqjfn2"] # centos6 based
  }
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-centos-6-base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.centos6_base.use_encrypted]
  }
  owners            = [var.amis.owner_account_id]      # Our AMIs live under the Core account
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our CentOS 7 base (inherit from vanilla CentOS 7 with yum updated, OS hardening, installs (diagnostic tools, CloudWatchAgent, Telegraf)
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce --filters Name=name,Values=prpl-centos-7-base-*
data "aws_ami" "centos-7-base" {
  most_recent = true
  # centos7 based
  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-centos-7-base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.centos7_base.use_encrypted]
  }
  owners            = [var.amis.owner_account_id]      # Our AMIs live under the Core account
}
# Note: No aws_ami_launch_permission for Base image since on derived images from it should be being used outside of Core.

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our CentOS 7 PRPL application host
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce --filters Name=name,Values=prpl-centos-7-prpl-*
data "aws_ami" "centos-7-prpl" {
  count             = var.amis.centos7_prpl.enabled ? 1 : 0
  most_recent = true
  # centos7 based
  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-centos-7-prpl-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.centos7_prpl.use_encrypted]
  }
  owners            = [var.amis.owner_account_id]      # Our AMIs live under the Core account
}
# Note: No aws_ami_launch_permission for Base image since on derived images from it should be being used outside of Core.
