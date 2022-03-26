# ---------------------------------------------------------------------------------------------------------------------
# Kubernetes : deploy the AWS Load Balancer Controller
# Uses Helm charts
# ---------------------------------------------------------------------------------------------------------------------
module "alb_ingress_controller" {
  count  = contains(var.prpl_deploy_modes, "EKS") ? 1 : 0
  source = "github.com/GSA/terraform-kubernetes-aws-load-balancer-controller.git?ref=v5.0.1"
  # source                  = "../../../../../../terraform-modules/terraform-kubernetes-aws-load-balancer-controller"
  aws_resource_name_prefix  = ""
  k8s_cluster_type          = "eks"
  k8s_namespace             = "kube-system"
  aws_region_name           = module.global_variables.aws_region
  k8s_cluster_name          = module.k8s[0].k8s_cluster_name
  aws_vpc_id                = module.vpc.vpc_id
  alb_controller_depends_on = []
  depends_on                = [module.k8s]
}
