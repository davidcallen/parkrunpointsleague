# ---------------------------------------------------------------------------------------------------------------------
# Kubernetes : deploy the Kubernetes Dashboard on our Kubernetes cluster
# Uses Helm charts
# ---------------------------------------------------------------------------------------------------------------------
module "k8s-dashboard" {
  count  = contains(var.prpl_deploy_modes, "EKS") ? 1 : 0
  source = "../../../../../terraform-modules/terraform-module-k8s-dashboard"
  # source      = "git@github.com:davidcallen/terraform-module-k8s-dashboard.git?ref=1.0.0"
  global_default_tags = module.global_variables.default_tags
  depends_on          = [module.k8s-cluster-eks]
}
