output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs.id
}
output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs.name
}
output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs-container-agent.arn
}
output "ecs_cluster_efs_security_group_id" {
  value = aws_security_group.ecs-efs.id
}
output "ecs_cluster_service_registry_arn" {
  value = aws_service_discovery_service.ecs.arn
}