# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch Logs for ECS Container Instances (tested on EC2, not yet on Fargate)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs-container-instance-audit" {
  name              = "ecs-container-instance-audit"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name = "ecs-container-instance-audit"
  })
}
resource "aws_cloudwatch_log_group" "ecs-container-instance-agent" {
  name              = "ecs-container-instance-agent"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name = "ecs-container-instance-agent"
  })
}
resource "aws_cloudwatch_log_group" "ecs-container-instance-init" {
  name              = "ecs-container-instance-init"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name = "ecs-container-instance-init"
  })
}
resource "aws_cloudwatch_log_group" "ecs-container-instance-volume-plugin" {
  name              = "ecs-container-instance-volume-plugin"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(var.global_default_tags, var.environment.default_tags, {
    Name = "ecs-container-instance-volume-plugin"
  })
}
