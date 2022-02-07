# ---------------------------------------------------------------------------------------------------------------------
# Security Group for an EC2 instance doing a Packer build (windows and linux) (SSH, RDP, WinRM)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "packer" {
  name        = "${var.environment.resource_name_prefix}-packer-builder"
  description = "Packer builder access (SSH, RDP, WinRM)"
  vpc_id      = var.vpc_id
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-packer-builder"
    Application     = "Packer Builder"
  })
}

# All ingress to port 5986 (WinRM-HTTPS)
resource "aws_security_group_rule" "packer-allow-ingress-winrm-https" {
  type            = "ingress"
  description     = "WinRM-HTTPS"
  from_port       = 5986
  to_port         = 5986
  protocol        = "tcp"
  cidr_blocks     = var.allowed_ingress_cidrs_winrm
  security_group_id = aws_security_group.packer.id
}
# All ingress to port 3389 (RDP)
resource "aws_security_group_rule" "packer-allow-ingress-rdp" {
  type            = "ingress"
  description     = "rdp"
  from_port       = 3389
  to_port         = 3389
  protocol        = "tcp"
  cidr_blocks     = var.allowed_ingress_cidrs_rdp
  security_group_id = aws_security_group.packer.id
}
# All ingress to port 22 (SSH)
resource "aws_security_group_rule" "packer-allow-ingress-ssh" {
  type            = "ingress"
  description     = "ssh"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = var.allowed_ingress_cidrs_ssh
  security_group_id = aws_security_group.packer.id
}

# Allow egress to all ip addresses
resource "aws_security_group_rule" "packer-allow-egress-all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = -1
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.packer.id
}

