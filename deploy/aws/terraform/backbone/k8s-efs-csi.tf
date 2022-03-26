# ---------------------------------------------------------------------------------------------------------------------
# Kubernetes : deploy the AWS EFS CSI Driver on our Kubernetes cluster
# Note: Will uses Helm charts
# ---------------------------------------------------------------------------------------------------------------------
module "k8s-efs-csi" {
  count  = contains(var.prpl_deploy_modes, "EKS") ? 1 : 0
  source = "../../../../../terraform-modules/terraform-module-aws-k8s-efs-csi"
  # source      = "git@github.com:davidcallen/terraform-module-aws-k8s-efs-csi.git?ref=1.0.0"
  aws_region      = module.global_variables.aws_region
  org_domain_name = module.global_variables.org_domain_name
  # org_short_name           = module.global_variables.org_short_name
  name                         = var.environment.resource_name_prefix
  namespace                    = module.global_variables.org_short_name
  environment                  = var.environment
  vpc_id                       = module.vpc.vpc_id
  vpc_private_subnet_ids       = module.vpc.private_subnets
  vpc_private_subnet_cidrs     = module.vpc.private_subnets_cidr_blocks
  cluster_name                 = module.k8s[0].k8s_cluster_name
  cluster_identity_oidc_issuer = module.k8s[0].k8s_cluster_identity_oidc_issuer
  cluster_ingress_allowed_cidrs = concat(
    module.vpc.private_subnets_cidr_blocks,
    module.global_variables.allowed_org_private_network_cidrs,
    module.global_variables.allowed_org_vpn_cidrs
  )
  dynamic_provisioning_enabled = false
  global_default_tags          = module.global_variables.default_tags
  depends_on                   = [module.k8s]
}
