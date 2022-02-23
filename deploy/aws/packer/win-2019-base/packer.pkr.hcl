variable "ami_description" {
  type    = string
  default = "win-2019-base"
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
data "amazon-ami" "win-2019-from-amazon" {
  filters = {
    owner-alias         = "amazon"
    name                = "Windows_Server-2019-English-Full-Base-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
    # product-code        = "aw0evgkw8e5c1q413zgy5pjce"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = "${var.aws_region}"
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
  source_ami                  = data.amazon-ami.win-2019-from-amazon.id
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
  provisioner "powershell" {
    scripts = [
      "./build-scripts/disable-uac.ps1",
      "./build-scripts/ChocolateyInstall.ps1",
      "./build-scripts/install-ad-powershell-tools.ps1"
    ]
  }
  provisioner "powershell" {
    elevated_user     = "Administrator"
    elevated_password = "4vwgx6irI!s3WwbjijkBFmS-nIbKkOmp"
    scripts = [
      "./build-scripts/install-openssh.ps1"
    ]
  }
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }
  provisioner "powershell" {
    inline = [
      "echo --------------------------------------------------------------------------------------------------------",
      "echo \"-- Choco install openssh, openjdk8, awscli, 7zip, notepad++, Cmder, putty 32-bit [so works with kerberos] \"",
      "echo --------------------------------------------------------------------------------------------------------",
      "Get-Date",
      "choco install openssh --yes --no-progress --failonstderr -params '\"/SSHServerFeature\"'",
      "choco install openjdk8 --yes --no-progress --failonstderr",
      "choco install awscli --yes --no-progress --failonstderr",
      "choco install wget --yes --no-progress --failonstderr",
      "choco install 7zip --yes --no-progress --failonstderr",
      "[Environment]::SetEnvironmentVariable(\"Path\", [Environment]::GetEnvironmentVariable(\"Path\", [EnvironmentVariableTarget]::Machine) + \";C:\\Program Files\\7-Zip\", [EnvironmentVariableTarget]::Machine)",
      "choco install Cmder --yes --no-progress --failonstderr",
      "choco install putty.install --yes --no-progress --failonstderr --x86",
      "choco install notepadplusplus --yes --no-progress --failonstderr",
      "Get-Date"
    ]
  }
  provisioner "file" {
    source      = "./files/ProgramData/Amazon/AmazonCloudWatchAgent/amazon-cloudwatch-agent.json"
    destination = "C:\\Users\\Administrator\\amazon-cloudwatch-agent.json"
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
