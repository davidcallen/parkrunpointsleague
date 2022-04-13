# ---------------------------------------------------------------------------------------------------------------------
# Cert-Manager for HTTPS on ingresses
# ---------------------------------------------------------------------------------------------------------------------
locals {
  use_lets_encrypt_staging_for_testing = false
  ingress_nginx_in_use                 = true
  ingress_class                        = local.ingress_nginx_in_use ? "nginx" : "traefik"
  cluster_issuer                       = local.use_lets_encrypt_staging_for_testing ? "letsencrypt-staging" : "letsencrypt-prod"
  use_kube2iam                         = true
}
# TODO : Try this module instead of mine. https://registry.terraform.io/modules/terraform-iaac/cert-manager/kubernetes/latest
module "k8s-cert-manager" {
  # count  = contains(var.prpl_deploy_modes, "EKS") ? 1 : 0
  source = "../../../../../terraform-modules/terraform-module-aws-k8s-cert-manager"
  # source      = "git@github.com:davidcallen/terraform-module-aws-k8s-cert-manager.git?ref=1.0.0"
  aws_region                           = module.global_variables.aws_region
  environment                          = var.environment
  route53_private_hosted_zone_id       = module.dns[0].route53_private_hosted_zone_id
  route53_public_hosted_zone_id        = module.dns[0].route53_public_subdomain_hosted_zone_id
  use_lets_encrypt_staging_for_testing = local.use_lets_encrypt_staging_for_testing
  ingress_nginx_in_use                 = local.ingress_nginx_in_use
  letsencrypt_contact_email            = "david.c.allen1971@gmail.com"
  dns_zones = [
    "${var.environment.name}-${module.global_variables.org_domain_name}",
    module.global_variables.org_domain_name
  ]
  # Leave AWS User credentials blank since Kube2iam will
  cert_manager_aws_user_access_key     = (local.use_kube2iam) ? "" : local.secrets_primary.data["cert-manager-aws-user.access-key"]
  cert_manager_aws_user_secret_key     = (local.use_kube2iam) ? "" : local.secrets_primary.data["cert-manager-aws-user.secret-key"]
  iam_config = {
    use_instance_profile_role  = local.use_kube2iam
    instance_profile_role_name = module.k8s-rancher-self-provisioned-managed-cluster.instance_profile_role_name
  }
  global_default_tags = module.global_variables.default_tags
  depends_on          = [module.k8s-rancher-self-provisioned-managed-cluster, helm_release.kube2iam]
}
data "aws_route53_zone" "public" {
  name = "${var.environment.name}.${module.global_variables.org_domain_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Certificate requests and ingress for demo app
# ---------------------------------------------------------------------------------------------------------------------
resource "kubectl_manifest" "certificate-kube-backbone" {
  validate_schema = false
  yaml_body       = <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kube-backbone-prpl
  namespace: default
spec:
  secretName: kube-backbone-prpl-tls
  issuerRef:
    name: ${local.cluster_issuer}
    kind: ClusterIssuer
  commonName: 'kube.backbone.parkrunpointsleague.org'
  dnsNames:
    - 'kube.backbone.parkrunpointsleague.org'
EOF
  depends_on      = [module.k8s-cert-manager]
}
resource "kubectl_manifest" "ingress-kube-backbone" {
  validate_schema = false
  yaml_body       = <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo
  annotations:
    kubernetes.io/ingress.class: ${local.ingress_class}
    cert-manager.io/cluster-issuer: ${local.cluster_issuer}
  labels:
    app: demo
spec:
  rules:
    - host: kube.backbone.parkrunpointsleague.org
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: demo
                port:
                  number: 8080
  tls:
    - hosts:
        - kube.backbone.parkrunpointsleague.org
      secretName: kube-backbone-prpl-tls
EOF
  depends_on      = [module.k8s-cert-manager]
}


