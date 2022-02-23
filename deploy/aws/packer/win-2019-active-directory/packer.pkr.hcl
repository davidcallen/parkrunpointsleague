variable "ami_description" {
  type    = string
  default = "win-2019-active-directory"
}
variable "aws_region" {
  type    = string
  default = "${env("AWS_REGION")}"
}
variable "prpl_ami_encrypted" {
  type    = string
  default = "${env("PRPL_AMI_ENCRYPTED")}"
}
variable "prpl_ami_encrypted_kms_key_id" {
  type    = string
  default = "${env("PRPL_AMI_ENCRYPTED_KMS_KEY_ID")}"
}
variable "prpl_ami_prefix_name" {
  type    = string
  default = "${env("PRPL_AMI_PREFIX_NAME")}"
}
variable "prpl_ami_suffix_name" {
  type    = string
  default = "${env("PRPL_AMI_SUFFIX_NAME")}"
}
variable "prpl_environment" {
  type    = string
  default = "${env("PRPL_ENVIRONMENT")}"
}
variable "prpl_git_commit_id" {
  type    = string
  default = "${env("PRPL_GIT_COMMIT_ID")}"
}
variable "prpl_org_short_name" {
  type    = string
  default = "${env("PRPL_ORG_SHORT_NAME")}"
}
variable "prpl_yum_update_enabled" {
  type    = string
  default = "${env("PRPL_YUM_UPDATE_ENABLED")}"
}
data "amazon-ami" "win-2019-base" {
  filters = {
    name                = "${var.prpl_ami_prefix_name}${var.prpl_org_short_name}-win-2019-base-*${var.prpl_ami_suffix_name}"
    # product-code        = "aw0evgkw8e5c1q413zgy5pjce"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["self"]
}
locals {
  ami_name = "${var.prpl_ami_prefix_name}${var.prpl_org_short_name}-${var.ami_description}-${legacy_isotime("20060125-150405")}-${var.prpl_git_commit_id}${var.prpl_ami_suffix_name}"
}

source "amazon-ebs" "build" {
  ami_description       = "${local.ami_name}"
  ami_name              = "${local.ami_name}"
  iam_instance_profile  = "packer-builder"
  instance_type         = "t3a.large"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    encrypted   = "${var.prpl_ami_encrypted}"
    kms_key_id  = "${var.prpl_ami_encrypted_kms_key_id}"
    delete_on_termination = true
  }
  region  = "${var.aws_region}"
  run_tags = {
    Name      = "${var.prpl_org_short_name}-packer-${var.ami_description}"
    Basename  = "${var.prpl_org_short_name}-${var.ami_description}"
  }
  run_volume_tags = {
    Name = "${var.prpl_org_short_name}-packer-${var.ami_description}"
  }
  security_group_filter {
    filters = {
      "tag:Name" = "${var.prpl_org_short_name}-${var.prpl_environment}-packer-builder"
    }
  }
  force_delete_snapshot = true
  force_deregister      = true
  snapshot_tags = {
    Encrypted        = "${var.prpl_ami_encrypted}"
    GitCommitId      = "${var.prpl_git_commit_id}"
    Name             = "${local.ami_name}"
    Basename         = "${var.prpl_org_short_name}-${var.ami_description}"
  }
  source_ami                  = "${data.amazon-ami.win-2019-base.id}"
  user_data_file              = "./build-scripts/SetupWinRM.ps1"
  communicator                = "winrm"
  winrm_username              = "Administrator"
  winrm_password              = "4vwgx6irI!s3WwbjijkBFmS-nIbKkOmp"
  winrm_insecure              = true
  winrm_use_ssl               = true
//  ssh_username              = "centos"
//  ssh_keypair_name          = "${var.prpl_org_short_name}-${var.prpl_environment}-ssh-key-packer-builder"
//  ssh_private_key_file      = "~/.ssh/${var.prpl_org_short_name}-aws/${var.prpl_org_short_name}-${var.prpl_environment}-ssh-key-packer-builder"
//  ssh_clear_authorized_keys = true
  subnet_filter {
    filters = {
      state             = "available"
      "tag:Environment" = "${var.prpl_environment}"
      "tag:Visibility"  = "private"
    }
    most_free = true
    random    = false
  }
  tags = {
    Encrypted        = "${var.prpl_ami_encrypted}"
    GitCommitId      = "${var.prpl_git_commit_id}"
    Name             = "${local.ami_name}"
    Basename         = "${var.prpl_org_short_name}-${var.ami_description}"
  }
  vpc_filter {
    filters = {
      isDefault         = "false"
      "tag:Environment" = "${var.prpl_environment}"
      "tag:Name"        = "${var.prpl_org_short_name}-${var.prpl_environment}-vpc"
    }
  }
}

build {
  sources = [
    "source.amazon-ebs.build"
  ]
  provisioner "file" {
    source      = "./files/ProgramData/Amazon/AmazonCloudWatchAgent/amazon-cloudwatch-agent-active-directory.json"
    destination = "C:\\ProgramData\\Amazon\\AmazonCloudWatchAgent\\Configs\\amazon-cloudwatch-agent-active-directory.json"
  }
  provisioner "powershell" {
    scripts = [
      "./build-scripts/install-active-directory.ps1"
      # "./build-scripts/install-admin-center.ps1"
    ]
  }
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }
  provisioner "powershell" {
    environment_vars = ["WINRMPASS={{.WinRMPassword}}"]
    inline = [
      "echo --------------------------------------------------------------------------------------------------------",
      "echo \"-- Sysprep and initialize disks \"",
      "echo --------------------------------------------------------------------------------------------------------",
      "Get-Date",
      "echo WINRM_PASSWORD=$Env:WINRMPASS",
      "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeInstance.ps1 -Schedule",
      "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeDisks.ps1 -Schedule",
      "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\SysprepInstance.ps1 -NoShutdown",
      "Get-Date"
    ]
  }
}
