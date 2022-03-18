module "ecs-prpl" {
  count                             = contains(var.prpl_deploy_modes, "ECS") ? 1 : 0
  source                            = "./ecs-prpl"
  aws_region                        = module.global_variables.aws_region
  name_suffix                       = ""
  environment                       = var.environment
  vpc_id                            = module.vpc.vpc_id
  vpc_private_subnet_ids            = module.vpc.private_subnets
  vpc_private_subnet_cidrs          = module.vpc.private_subnets_cidr_blocks
  ecs_cluster_id                    = module.ecs[0].ecs_cluster_id
  ecs_cluster_name                  = module.ecs[0].ecs_cluster_name
  ecs_cluster_efs_security_group_id = module.ecs[0].ecs_cluster_efs_security_group_id
  // ecs_task_execution_role_arn       = module.ecs[0].ecs_task_execution_role_arn
  ecr_repository_name = "${module.global_variables.org_domain_name}/prpl"
  ecr_image_tag       = "20220314101846"
  # load_balancer_target_group_arn_http     = aws_lb_target_group.ecs-qa-mail-http.arn
  //  allowed_egress_cidrs = {
  //    http  = concat(module.global_variables.allowed_org_private_network_cidrs, module.vpc.private_subnets_cidr_blocks)
  //    https = concat(module.global_variables.allowed_org_private_network_cidrs, module.vpc.private_subnets_cidr_blocks)
  //  }
  prpl_database_user_password  = local.secrets_primary.data["prpl-db-user.password"]
  prpl_database_admin_password = local.secrets_primary.data["prpl-db-admin.password"]
  global_default_tags          = module.global_variables.default_tags
}


//resource "aws_lb_target_group" "ecs-qa-mail-http" {
//  name        = "${var.environment.resource_name_prefix}-ecs-qa-mail-http"
//  target_type = "instance"
//  port        = 80
//  protocol    = "TCP"
//  vpc_id      = module.vpc.vpc_id
//  deregistration_delay = 0    # Prevent failing instance from lingering
//}
//resource "aws_lb_listener" "ecs-qa-mail-http" {
//  load_balancer_arn = module.lb-private.load-balancer.arn
//  port              = 80
//  protocol          = "TCP"
//  default_action {
//    type             = "forward"
//    target_group_arn = aws_lb_target_group.ecs-qa-mail-http.arn
//  }
//}
