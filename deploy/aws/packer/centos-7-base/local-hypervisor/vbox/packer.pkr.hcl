variable "ami_description" {
  type    = string
  default = "centos-7-base"
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
variable "prpl_centos_vbox_iso_to_ovf_filenamepath" {
  type    = string
  default = "${env("PRPL_CENTOS_VBOX_ISO_TO_OVF_FILENAMEPATH")}"
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

locals {
  ami_name = "${var.prpl_ami_prefix_name}${var.prpl_org_short_name}-${var.ami_description}-${legacy_isotime("20060125-150405")}-${var.prpl_git_commit_id}${var.prpl_ami_suffix_name}"
  centos_user_ssh_public_key = file("~/.ssh/${var.prpl_org_short_name}-aws/${var.prpl_org_short_name}-${var.prpl_environment}-ssh-key-packer-builder.pub")
  instance_id = uuidv4()
}
source "file" "cloud-init-user-data" {
  content                   =  templatefile("cloud-init-user-data.tpl", {
    "centos_user_ssh_public_key" = "${local.centos_user_ssh_public_key}"
  })
  target                    =  "${path.root}/cloud-init-floppy/user-data"
}
source "file" "cloud-init-meta-data" {
  content                   =  "instance-id: ${local.instance_id}"
  target                    =  "${path.root}/cloud-init-floppy/meta-data"
}
source "virtualbox-ovf" "build" {
  vm_name                   = "${local.ami_name}"
  guest_additions_mode      = "attach"
  headless                  = "false"
  source_path               = "${var.prpl_centos_vbox_iso_to_ovf_filenamepath}"
  ssh_username              = "centos"
  ssh_private_key_file      = "~/.ssh/${var.prpl_org_short_name}-aws/${var.prpl_org_short_name}-${var.prpl_environment}-ssh-key-packer-builder"
  ssh_clear_authorized_keys = "true"
  ssh_timeout               = "600s"
  vboxmanage                = [
    ["modifyvm", "{{ .Name }}", "--memory", "2048"],
    ["modifyvm", "{{ .Name }}", "--cpus", "4"],
    ["modifyvm", "{{ .Name }}", "--audio", "none"]
  ]
  floppy_files              = [
    "${path.root}/cloud-init-floppy/meta-data",
    "${path.root}/cloud-init-floppy/user-data"
  ]
  floppy_label              = "cidata"
  shutdown_command          = "echo 'packer' | sudo -S shutdown -P now"
  output_directory          = "${path.root}/output"
}

build {
  sources = [
    "sources.file.cloud-init-user-data",
    "sources.file.cloud-init-meta-data",
    "source.virtualbox-ovf.build"
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
      "-e PRPL_YUM_UPDATE_ENABLED='${var.prpl_yum_update_enabled}'",
      "-v"
    ]
  }
  provisioner "shell" {
    expect_disconnect = true
    inline            = [
      "set -x ; date ; uptime ; echo Rebooting to apply yum updates ; sudo reboot"
    ]
    inline_shebang    = "/bin/bash"
  }
  provisioner "shell" {
    inline         = [
      "date ; uptime ; echo ========================  Reboot Succeeded  =================================="
    ]
    inline_shebang = "/bin/bash"
    pause_before   = "1m0s"
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
