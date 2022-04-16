//# ---------------------------------------------------------------------------------------------------------------------
//# Kubernetes : Create the k8s EKS cluster  (currently using Fargate Nodes)
//# ---------------------------------------------------------------------------------------------------------------------
//module "k8s-cluster-eks" {
//  count  = contains(var.prpl_deploy_modes, "EKS") ? 1 : 0
//  source = "../../../../../terraform-modules/terraform-module-aws-k8s-cluster-eks"
//  # source                  = "git@github.com:davidcallen/terraform-module-aws-k8s-cluster-eks.git?ref=1.0.0"
//  aws_region               = module.global_variables.aws_region
//  org_domain_name          = module.global_variables.org_domain_name
//  name                     = var.environment.resource_name_prefix
//  namespace                = module.global_variables.org_short_name
//  environment              = var.environment
//  vpc_id                   = module.vpc.vpc_id
//  vpc_private_subnet_ids   = module.vpc.private_subnets
//  vpc_private_subnet_cidrs = module.vpc.private_subnets_cidr_blocks
//  cluster_internal_cidr    = "10.13.1.0/24"
//  cluster_ingress_allowed_cidrs = concat(
//    module.vpc.private_subnets_cidr_blocks,
//    module.global_variables.allowed_org_private_network_cidrs,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  global_default_tags = module.global_variables.default_tags
//}
//
//provider "kubernetes" {
//  host                   = module.k8s-cluster-eks[0].k8s_cluster_endpoint
//  cluster_ca_certificate = base64decode(module.k8s-cluster-eks[0].k8s_cluster_certificate_authority[0].data)
//  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator[0].token
//}
//provider "helm" {
//  kubernetes {
//    host                   = module.k8s-cluster-eks[0].k8s_cluster_endpoint
//    token                  = data.aws_eks_cluster_auth.aws_iam_authenticator[0].token
//    cluster_ca_certificate = base64decode(module.k8s-cluster-eks[0].k8s_cluster_certificate_authority[0].data)
//  }
//}
//
//data "aws_eks_cluster_auth" "aws_iam_authenticator" {
//  count  = contains(var.prpl_deploy_modes, "EKS") ? 1 : 0
//  name = module.k8s-cluster-eks[0].k8s_cluster_name
//}
