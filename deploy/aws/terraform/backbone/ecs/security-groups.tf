# ---------------------------------------------------------------------------------------------------------------------
# Security Group for all ECS Container Instances (nodes) (EC2 instances running docker daemon)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "ecs" {
  name              = "${var.environment.resource_name_prefix}-ecs-node"
  description       = "Security group common to all ECS Container Instances (nodes)"
  vpc_id            = var.vpc_id
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-ecs-agent"
    Application     = "ECS"
  })
}
# All ingress to all ports
resource "aws_security_group_rule" "ecs-allow-ingress" {
  type            = "ingress"
  description     = "all"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]             # TODO - change to var.allowed_ingress_cidrs.ssh
  security_group_id = aws_security_group.ecs.id
}
# All egress to https - this is needed by ECS agent to communicate to AWS Services, so it can register itself in the cluster !!
resource "aws_security_group_rule" "ecs-allow-egress-https" {
  type            = "egress"
  description     = "all"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Security Group for access to EFS for Volumes
# ---------------------------------------------------------------------------------------------------------------------
# Allow both ingress and egress for port 2049 (NFS) for our EC2 instances
# Restrict the traffic to within the VPC (and not outside).
resource "aws_security_group" "ecs-efs" {
  name              = "${var.environment.resource_name_prefix}-ecs-efs"
  description       = "Allows NFS traffic from instances within the VPC."
  vpc_id            = var.vpc_id
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks     = var.vpc_private_subnet_cidrs
  }
  egress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks     = var.vpc_private_subnet_cidrs
  }
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-ecs-efs"
    Application     = "ECS Cluster"
    ClusterName     = aws_ecs_cluster.ecs.name
  })
}