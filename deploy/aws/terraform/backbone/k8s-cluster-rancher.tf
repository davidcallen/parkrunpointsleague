# ---------------------------------------------------------------------------------------------------------------------
# Kubernetes : Create the k8s Rancher Server cluster and Managed Cluster (and register it with the Rancher Server)
# Note : to conveniently destroy these resources and dodge the provider issue use :
#   aws-vault exec prpl-$(basename $(realpath .)) -- terraform destroy --target module.k8s-rancher-managed-cluster --target module.k8s-rancher-self-provisioned-managed-cluster
# and then
#   aws-vault exec prpl-$(basename $(realpath .)) -- terraform destroy --target module.k8s-rancher-server-infra --target module.k8s-rancher-server-deploy
# ---------------------------------------------------------------------------------------------------------------------
locals {
  rancher_server_admin_password      = local.secrets_primary.data["rancher-server-admin.password"]
  rancher_server_hostname            = "rancher.${var.environment.name}.${module.global_variables.org_domain_name}"
  rancher_server_aws_user_access_key = local.secrets_primary.data["rancher-server-aws-user.access-key"]
  rancher_server_aws_user_secret_key = local.secrets_primary.data["rancher-server-aws-user.secret-key"]
  rancher_managed_cluster_hostname   = "kube.${var.environment.name}.${module.global_variables.org_domain_name}"
}
module "k8s-rancher-server-infra" {
  count  = contains(var.prpl_deploy_modes, "RANCHER") ? 1 : 0
  source = "../../../../../terraform-modules/terraform-module-aws-k8s-rancher-server-infra"
  # source                         = "git@github.com:davidcallen/terraform-module-aws-k8s-rancher-server-infra.git?ref=1.0.0"
  aws_region                       = module.global_variables.aws_region
  environment                      = var.environment
  vpc_id                           = module.vpc.vpc_id
  vpc_private_subnet_ids           = module.vpc.private_subnets
  vpc_private_subnet_cidrs         = module.vpc.private_subnets_cidr_blocks
  route53_private_hosted_zone_id   = module.dns[0].route53_private_hosted_zone_id
  rancher_server_dns               = local.rancher_server_hostname
  cluster_ssh_key_name             = aws_key_pair.ssh.key_name
  cluster_ssh_private_key_filename = "~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key"
  cluster_ingress_allowed_cidrs = concat(
    module.vpc.private_subnets_cidr_blocks,
    module.global_variables.allowed_org_private_network_cidrs,
    module.global_variables.allowed_org_vpn_cidrs
  )
  ec2_instance_type   = "t3a.small"
  global_default_tags = merge(module.global_variables.default_tags, var.environment.default_tags)
}
# Helm provider
provider "helm" {
  alias = "rancher-server"
  kubernetes {
    config_path = module.k8s-rancher-server-deploy.kube_config_yaml_filename
  }
}
# Rancher2 bootstrapping provider
provider "rancher2" {
  alias    = "bootstrap"
  api_url  = "https://${local.rancher_server_hostname}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  bootstrap = true
}
# Rancher resources
# TODO : split this into 2 modules - a Bootstrap and a Configure one (e.g. for adding the aws cloud credential)
module "k8s-rancher-server-deploy" {
  # count  = contains(var.prpl_deploy_modes, "RANCHER") ? 1 : 0
  source = "../../../../../terraform-modules/terraform-module-k8s-rancher-server-deploy"
  # source                                = "git@github.com:davidcallen/terraform-module-k8s-rancher-server-deploy.git?ref=1.0.0"
  aws_region                              = module.global_variables.aws_region
  node_public_ip                          = (module.k8s-rancher-server-infra[0].rancher_server_public_ip != "") ? module.k8s-rancher-server-infra[0].rancher_server_public_ip : module.k8s-rancher-server-infra[0].rancher_server_private_ip
  node_internal_ip                        = module.k8s-rancher-server-infra[0].rancher_server_private_ip
  node_username                           = module.k8s-rancher-server-infra[0].node_username
  cluster_ssh_private_key_filename        = "~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key"
  rancher_version                         = "v2.6.3"
  rancher_kubernetes_version              = "v1.21.8+k3s1"
  rancher_server_dns                      = local.rancher_server_hostname
  rancher_server_bootstrap_admin_password = local.rancher_server_admin_password
  rancher_server_use_self_signed_certs    = true
  cert_manager_version                    = "1.5.3"
  //  aws_user_credential_access_key          = local.rancher_server_aws_user_access_key
  //  aws_user_credential_secret_key          = local.rancher_server_aws_user_secret_key
  providers = {
    rancher2.bootstrap = rancher2.bootstrap
    helm               = helm.rancher-server
  }
}
# Rancher2 administration provider
provider "rancher2" {
  alias    = "admin"
  api_url  = "https://${local.rancher_server_hostname}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  token_key = module.k8s-rancher-server-deploy.rancher2_bootstrap_admin_token
  timeout   = "300s"
}

# Choose between below clusters deployment approaches :
# 1) nodes deployed by our terraform and then registered to Rancher Server, or
# 2) nodes deployed by Rancher Server (self-provisioned)

//# Cluster deployment approach : 1) nodes deployed by our terraform and then registered to Rancher Server.
//module "k8s-rancher-managed-cluster" {
//  # count  = contains(var.prpl_deploy_modes, "RANCHER") ? 1 : 0
//  source = "../../../../../terraform-modules/terraform-module-aws-k8s-rancher-managed-cluster"
//  # source                  = "git@github.com:davidcallen/terraform-module-aws-k8s-rancher-managed-cluster.git?ref=1.0.0"
//  environment                      = var.environment
//  vpc_id                           = module.vpc.vpc_id
//  vpc_private_subnet_ids           = module.vpc.private_subnets
//  vpc_private_subnet_cidrs         = module.vpc.private_subnets_cidr_blocks
//  route53_private_hosted_zone_id   = module.dns[0].route53_private_hosted_zone_id
//  cluster_name                     = "kube"
//  cluster_dns                      = local.rancher_managed_cluster_hostname
//  cluster_ssh_key_name             = aws_key_pair.ssh.key_name
//  cluster_ssh_private_key_filename = "~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key"
//  # cluster_ssh_private_key_filename = "/home/ec2-user/.ssh/id_rsa"
//  cluster_ingress_allowed_cidrs = concat(
//    module.vpc.private_subnets_cidr_blocks,
//    module.global_variables.allowed_org_private_network_cidrs,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  ec2_instance_type                    = "t3a.medium"
//  docker_version                       = "19.03"
//  windows_prefered_cluster             = false
//  kubernetes_distribution              = "K3S"
//  kubernetes_version                   = "v1.21.8+k3s1" # For k3s install on managed-cluster
//  rancher_server_use_self_signed_certs = true
//  k3s_deploy_traefik                   = false
//  install_nginx_ingress                = true
//  global_default_tags                  = module.global_variables.default_tags
//  providers = {
//    rancher2.admin = rancher2.admin
//  }
//}
//

# Cluster deployment approach : 2) nodes deployed by Rancher Server (self-provisioned)
module "k8s-rancher-self-provisioned-managed-cluster" {
  # count  = contains(var.prpl_deploy_modes, "RANCHER") ? 1 : 0
  source = "../../../../../terraform-modules/terraform-module-aws-k8s-rancher-self-provisioned-managed-cluster"
  # source                  = "git@github.com:davidcallen/terraform-module-aws-k8s-rancher-self-provisioned-managed-cluster.git?ref=1.0.0"
  environment                      = var.environment
  vpc_id                           = module.vpc.vpc_id
  vpc_private_subnet_ids           = module.vpc.private_subnets
  vpc_private_subnet_cidrs         = module.vpc.private_subnets_cidr_blocks
  route53_private_hosted_zone_id   = module.dns[0].route53_private_hosted_zone_id
  cluster_name                     = "kube"
  cluster_dns                      = local.rancher_managed_cluster_hostname
  cluster_ssh_key_name             = aws_key_pair.ssh.key_name
  cluster_ssh_private_key_filename = "~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key"
  cluster_ingress_allowed_cidrs = concat(
    module.vpc.private_subnets_cidr_blocks,
    module.global_variables.allowed_org_private_network_cidrs,
    module.global_variables.allowed_org_vpn_cidrs
  )
  ec2_instance_type                    = "t3a.medium"
  docker_version                       = "20.10" # Note: this version will need to be compatible with the AMI
  windows_prefered_cluster             = false
  kubernetes_distribution              = "RKE"
  kubernetes_version                   = "v1.22.7-rancher1-2" # or "v1.21.8+k3s1" for k3s install on managed-cluster
  rancher_server_use_self_signed_certs = true
  # rancher_server_aws_cloud_credential_name = module.k8s-rancher-server-deploy.rancher_server_aws_cloud_credential_name
  k3s_deploy_traefik             = false
  install_nginx_ingress          = true
  aws_region                     = module.global_variables.aws_region
  aws_zone                       = module.global_variables.aws_zones[module.global_variables.aws_zone_preferred_placement_index] # Currently limited to single-zone
  aws_user_credential_access_key = local.rancher_server_aws_user_access_key
  aws_user_credential_secret_key = local.rancher_server_aws_user_secret_key
  global_default_tags            = module.global_variables.default_tags
  providers = {
    rancher2.admin = rancher2.admin
  }
}
# Helm provider for our managed workload cluster
provider "helm" {
  kubernetes {
    host                   = module.k8s-rancher-self-provisioned-managed-cluster.cluster_host
    cluster_ca_certificate = base64decode(module.k8s-rancher-self-provisioned-managed-cluster.cluster_ca_certificate)
    token                  = module.k8s-rancher-self-provisioned-managed-cluster.token
  }
}
# Kubernetes provider for our managed workload cluster
provider "kubernetes" {
  host                   = module.k8s-rancher-self-provisioned-managed-cluster.cluster_host
  cluster_ca_certificate = base64decode(module.k8s-rancher-self-provisioned-managed-cluster.cluster_ca_certificate)
  token                  = module.k8s-rancher-self-provisioned-managed-cluster.token
}
# Kubectl provider for our managed workload cluster
provider "kubectl" {
  host                   = module.k8s-rancher-self-provisioned-managed-cluster.cluster_host
  cluster_ca_certificate = base64decode(module.k8s-rancher-self-provisioned-managed-cluster.cluster_ca_certificate)
  token                  = module.k8s-rancher-self-provisioned-managed-cluster.token
  load_config_file = false
}