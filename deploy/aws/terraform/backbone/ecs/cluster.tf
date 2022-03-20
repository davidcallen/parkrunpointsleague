resource "aws_ecs_cluster" "ecs" {
  name = "${var.environment.resource_name_prefix}-ecs-cluster"
}
resource "aws_service_discovery_private_dns_namespace" "ecs" {
  name        = "${var.environment.name}.${var.org_domain_name}"
  description = "Service Discovery for ${var.environment.name}.${var.org_domain_name}"
  vpc         = var.vpc_id
}
resource "aws_service_discovery_service" "ecs" {
  name = "${var.environment.resource_name_prefix}-ecs-cluster"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs.id
// Type A record only usable with awsvpc network mode
//    dns_records {
//      ttl  = 60
//      type = "A"
//    }
    dns_records {
      ttl  = 60
      type = "SRV"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
