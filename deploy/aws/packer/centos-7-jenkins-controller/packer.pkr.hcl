variable "ami_description" {
  type    = string
  default = "centos-7-jenkins-controller"
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
data "amazon-ami" "centos-7-base" {
  filters = {
    name                = "${var.prpl_ami_prefix_name}${var.prpl_org_short_name}-centos-7-base-*${var.prpl_ami_suffix_name}"
    product-code        = "aw0evgkw8e5c1q413zgy5pjce"
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
  force_delete_snapshot = true
  force_deregister      = true
  iam_instance_profile  = "packer-builder"
  instance_type         = "t3a.small"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    encrypted   = "${var.prpl_ami_encrypted}"
    kms_key_id  = "${var.prpl_ami_encrypted_kms_key_id}"
    delete_on_termination = true
  }
  region  = "${var.aws_region}"
  run_tags = {
    Name     = "${var.prpl_org_short_name}-packer-${var.ami_description}"
  }
  run_volume_tags = {
    Name     = "${var.prpl_org_short_name}-packer-${var.ami_description}"
    Basename = "${var.prpl_org_short_name}-${var.ami_description}"
  }
  security_group_filter {
    filters = {
      "tag:Name" = "${var.prpl_org_short_name}-${var.prpl_environment}-packer-builder"
    }
  }
  snapshot_tags = {
    Encrypted        = "${var.prpl_ami_encrypted}"
    GitCommitId      = "${var.prpl_git_commit_id}"
    Name             = "${local.ami_name}"
    Basename         = "${var.prpl_org_short_name}-${var.ami_description}"
  }
  source_ami                = "${data.amazon-ami.centos-7-base.id}"
  ssh_username              = "centos"
  ssh_keypair_name          = "${var.prpl_org_short_name}-${var.prpl_environment}-ssh-key-packer-builder"
  ssh_private_key_file      = "~/.ssh/${var.prpl_org_short_name}-aws/${var.prpl_org_short_name}-${var.prpl_environment}-ssh-key-packer-builder"
  ssh_clear_authorized_keys = true
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
  provisioner "ansible" {
    galaxy_file     = "./ansible/requirements.yml"
    playbook_file   = "./ansible/playbook.yml"
    roles_path      = "./ansible/roles"
    user            = "centos"
    use_proxy       = false
    extra_arguments = [
      "-e PRPL_ORG_SHORT_NAME='${var.prpl_org_short_name}'",
      "-e AMI_NAME='${local.ami_name}'",
      "-v"
    ]
  }
  provisioner "shell" {
    execute_command = "sudo -S sh '{{ .Path }}'"
    inline          = [
      "echo '# Shredding sensitive data for user root...'",
      "[ -f /root/.ssh/authorized_keys ] && shred -u /root/.ssh/authorized_keys",
      "[ -f /root/.bash_history ] && shred -u /root/.bash_history",
      "echo '# Shredding sensitive data for user centos...'",
      "[ -d /home/centos ] && [ -f /home/centos/.bash_history ] && shred -u /home/centos/.bash_history",
      "sync; sleep 1; sync"
    ]
    inline_shebang  = "/bin/sh -e -x"
  }
}
