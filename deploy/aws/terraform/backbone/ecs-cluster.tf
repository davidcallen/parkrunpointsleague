# ---------------------------------------------------------------------------------------------------------------------
# ECS : Create the ECS Cluster
# ---------------------------------------------------------------------------------------------------------------------
module "ecs" {
  count                         = contains(var.prpl_deploy_modes, "ECS") ? 1 : 0
  source                        = "../../../../../terraform-modules/terraform-module-aws-ecs-cluster"
  # source                      = "git@github.com:davidcallen/terraform-module-aws-ecs-cluster.git?ref=1.0.0"
  name                          = var.environment.resource_name_prefix
  environment                   = var.environment
  vpc_id                        = module.vpc.vpc_id
  vpc_private_subnet_ids        = module.vpc.private_subnets
  vpc_private_subnet_cidrs      = module.vpc.private_subnets_cidr_blocks
  cluster_ingress_allowed_cidrs = concat(module.global_variables.allowed_org_private_network_cidrs, module.vpc.private_subnets_cidr_blocks)
  cluster_egress_allowed_cidrs  = concat(module.global_variables.allowed_org_private_network_cidrs, module.vpc.private_subnets_cidr_blocks)
  cluster_node_ssh_key_name     = aws_key_pair.ssh.key_name
  global_default_tags           = module.global_variables.default_tags
}
