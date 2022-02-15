# ---------------------------------------------------------------------------------------------------------------------
# Create ssh_key_pair and upload ssh public key from file to there
#   Requires an ssh key to already exist that was created like "ssh-keygen -f ~/.ssh/prpl-aws/prpl-foobar-ssh-key -t rsa -b 2048 -m pem"
# Would like to use ECDSA or ED25519, but restricted because :
#  1) data.tls_public_key only supports RSA and ECDSA
#  2) EC2 aws_key_pair only supports RSA and ED25519
# ---------------------------------------------------------------------------------------------------------------------
data "tls_public_key" "packer-ssh-key-public" {
  private_key_pem = file("~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key-packer-builder")
}
resource "aws_key_pair" "packer" {
  key_name   = "${var.environment.resource_name_prefix}-ssh-key-packer-builder"
  public_key = data.tls_public_key.packer-ssh-key-public.public_key_openssh
}
