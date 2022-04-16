//# ---------------------------------------------------------------------------------------------------------------------
//# Kubernetes : deploy the Jenkins app on our Kubernetes cluster
//# Uses Helm charts
//# ---------------------------------------------------------------------------------------------------------------------
//module "k8s-jenkins" {
//  count  = contains(var.prpl_deploy_modes, "EKS") ? 1 : 0
//  source = "../../../../../terraform-modules/terraform-module-aws-k8s-jenkins"
//  # source                    = "git@github.com:davidcallen/terraform-module-aws-k8s-jenkins.git?ref=1.0.0"
//  aws_region                    = module.global_variables.aws_region
//  org_domain_name               = module.global_variables.org_domain_name
//  org_short_name                = module.global_variables.org_short_name
//  name                          = var.environment.resource_name_prefix
//  namespace                     = module.global_variables.org_short_name
//  environment                   = var.environment
//  vpc_id                        = module.vpc.vpc_id
//  vpc_public_subnet_ids         = module.vpc.public_subnets
//  vpc_public_subnet_cidrs       = module.vpc.public_subnets_cidr_blocks
//  vpc_private_subnet_ids        = module.vpc.private_subnets
//  vpc_private_subnet_cidrs      = module.vpc.private_subnets_cidr_blocks
//  cluster_name                  = module.k8s-cluster-eks[0].k8s_cluster_name
//  cluster_security_group_efs_id = module.k8s-efs-csi[0].security_group_efs_id
//  cluster_ingress_allowed_cidrs = concat(
//    module.vpc.private_subnets_cidr_blocks,
//    module.global_variables.allowed_org_private_network_cidrs,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//  dynamic_efs_provisioning_enabled = false # Cannot set this to true if k8s cluster using Fargate !
//  storage_class_name               = module.k8s-efs-csi[0].storage_class_name
//  route53_enabled                  = module.global_variables.route53_enabled
//  route53_private_hosted_zone_id   = (module.global_variables.route53_enabled) ? module.dns[0].route53_private_hosted_zone_id : ""
//  route53_public_hosted_zone_id    = (module.global_variables.route53_enabled) ? module.dns[0].route53_public_subdomain_hosted_zone_id : ""
//  ha_high_availability_enabled     = true
//  ha_public_load_balancer = {
//    enabled       = false
//    port          = 443
//    hostname_fqdn = "jenkins.${var.environment.name}.${module.global_variables.org_domain_name}"
//    ssl_cert = {
//      use_amazon_provider = true # Has the overhead of needing external DNS verification to activate it
//      use_self_signed     = false
//    }
//    allowed_ingress_cidrs = {
//      https = concat(
//        module.global_variables.allowed_org_private_network_cidrs,
//        [var.vpc.cidr_block], # Note we allow complete vpc.cidr_block since we have a public load balancer
//      )
//    }
//    # Dont want customers reaching internal healthcheck page
//    disallow_ingress_internal_health_check_from_cidrs = []
//  }
//  ha_private_load_balancer = {
//    enabled       = true
//    port          = 443
//    hostname_fqdn = "jenkins.${var.environment.name}.${module.global_variables.org_domain_name}"
//    ssl_cert = {
//      use_amazon_provider = true # Has the overhead of needing external DNS verification to activate it
//      use_self_signed     = false
//    }
//    allowed_ingress_cidrs = {
//      https = concat(
//        module.global_variables.allowed_org_private_network_cidrs,
//        [var.vpc.cidr_block], # Note we allow complete vpc.cidr_block since we have a public load balancer
//      )
//    }
//    # Dont want customers reaching internal healthcheck page
//    disallow_ingress_internal_health_check_from_cidrs = []
//  }
//  jenkins_admin_password = local.secrets_primary.data["jenkins-admin.password"]
//  global_default_tags    = module.global_variables.default_tags
//  depends_on             = [
//    module.k8s-cluster-eks,
//    module.k8s-efs-csi,
//    module.alb_ingress_controller
//  ]
//}
//output "jenkins_pvc_id" {
//  value = contains(var.prpl_deploy_modes, "EKS") ? module.k8s-jenkins[0].pvc_id : ""
//}