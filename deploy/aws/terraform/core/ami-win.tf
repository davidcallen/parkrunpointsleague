# ---------------------------------------------------------------------------------------------------------------------
# AMI for Windows Server Base 2019 from Amazon/Microsoft
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners amazon --filters Name=name,Values=Windows_Server-2019-English-Full-Base*
# aws --region eu-west-1 ec2 describe-images --owners amazon --filters Name=name,Values=Windows_Server-2019-English-Full-Base-*
data "aws_ami" "windows-server-full-2019" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"] # 801119661308
}
# aws --region eu-west-1 ec2 describe-images --owners amazon --filters Name=name,Values=Windows_Server-2019-English-Core-Base-*
data "aws_ami" "windows-server-core-2019" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Core-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"] # 801119661308
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our Windows 2019 Full Base
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=name,Values=prpl-win-2019-base-*
data "aws_ami" "win-2019-base" {
  count       = var.amis.win-base.enabled ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-win-2019-base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.win-base.use_encrypted]
  }
  owners = ["self"]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our Windows 2019 Core Base
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=name,Values=prpl-win-2019-core-base-*
data "aws_ami" "win-2019-core-base" {
  count       = var.amis.win-core-base.enabled ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-win-2019-core-base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.win-core-base.use_encrypted]
  }
  owners = ["self"]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our Windows 2019 Active Directory - Full
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=name,Values=prpl-win-2019-active-directory-*
data "aws_ami" "win-2019-active-directory" {
  count       = var.amis.win-active-directory.enabled ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-win-2019-active-directory-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.win-active-directory.use_encrypted]
  }
  owners = ["self"]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our Windows 2019 Active Directory - Core
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=name,Values=prpl-win-2019-core-active-directory-*
data "aws_ami" "win-2019-core-active-directory" {
  count       = (var.amis.win-core-base.enabled && var.amis.win-active-directory.enabled) ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-win-2019-core-active-directory-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.win-active-directory.use_encrypted]
  }
  owners = ["self"]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our Windows 2019 Desktop - Base
# ---------------------------------------------------------------------------------------------------------------------
# aws --region eu-west-1 ec2 describe-images --owners self --filters Name=name,Values=prpl-win-2019-dev-desktop-*
data "aws_ami" "win-2019-desktop-base" {
  count       = var.amis.win-desktop.enabled ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-win-2019-desktop-base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.win-desktop.use_encrypted]
  }
  owners = ["self"]
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI for our Windows 2019 Desktop - Dev
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "win-2019-desktop-dev" {
  count       = var.amis.win-desktop.enabled ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.amis.name_prefix}${module.global_variables.org_short_name}-win-2019-desktop-dev-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.encrypted"
    values = [var.amis.win-desktop.use_encrypted]
  }
  owners = ["self"]
}


