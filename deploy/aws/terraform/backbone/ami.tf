# ---------------------------------------------------------------------------------------------------------------------
# Get AMI Ids for use in our terraforming
# ---------------------------------------------------------------------------------------------------------------------
locals {
  ami_owner_centos_org = "679593333241"
  ami_owner_canonical = "099720109477"
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

data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = [local.ami_owner_canonical]
  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/*/ubuntu-focal-20.04-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}