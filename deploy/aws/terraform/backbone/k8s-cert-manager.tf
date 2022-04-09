locals {
  use_lets_encrypt_staging_for_testing = true
}
# ---------------------------------------------------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "cert-manager" {
  name        = "${var.environment.resource_name_prefix}-cert-manager"
  description = "Allow Cert Manager to update the DNS in Route53"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/${data.aws_route53_zone.public.id}"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF
}
data "aws_route53_zone" "public" {
  name = "${var.environment.name}.${module.global_variables.org_domain_name}"
}
data "aws_iam_user" "cert-manager" {
  user_name = "cert-manager"
}
resource "aws_iam_user_policy_attachment" "cert-manager" {
  user       = data.aws_iam_user.cert-manager.user_name
  policy_arn = aws_iam_policy.cert-manager.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53
# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_route53_record" "cert-manager-cert-dns-name" {
//  allow_overwrite = true
//  name            = "kube.${var.environment.name}.${module.global_variables.org_domain_name}"
//  # records         = [module.k8s-rancher-managed-cluster.workload_node_ip]
//  records         = ["90.250.8.71"] # needs to be a public IP
//  ttl             = 60
//  type            = "A"
//  zone_id         = data.aws_route53_zone.public.id
//}

//# Is below really necessary - test it ....
//#
//# As detailed here https://cert-manager.io/docs/configuration/acme/dns01/
//# Create a CNAME for ACME in TLD to point to subdomain
//resource "aws_route53_record" "delegate-to-public-subdomain-in-this-account" {
//  allow_overwrite = true
//  name            = "_acme-challenge.${module.global_variables.org_domain_name}"
//  records         = ["_acme-challenge.${var.environment.name}.${module.global_variables.org_domain_name}"]
//  ttl             = 60
//  type            = "CNAME"
//  zone_id         = data.aws_route53_zone.public-tld.id
//}
//data "aws_route53_zone" "public-tld" {
//  name = module.global_variables.org_domain_name
//}

# ---------------------------------------------------------------------------------------------------------------------
# Helm cert manager install
# ---------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}
# Chart from here : https://github.com/kubernetes/dashboard/tree/master/aio/deploy/helm-chart/cert-manager
# Note that this will also deploy the Metrics Server
resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert-manager.id
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  set {
    name  = "version"
    value = "v1.8.0"
  }
  set {
    name  = "installCRDs"
    value = "true"
  }
  # We need to use the podDnsConfig.nameservers so cert-manager is using a public DNS not our private Route53 DNS zone.
  # Because the acme TXT records will be created by cert-manager in our Route53 public zone.
  set {
    name = "podDnsConfig.nameservers[0]"
    value ="8.8.8.8"
  }
  set {
    name = "podDnsConfig.nameservers[1]"
    value ="1.1.1.1"
  }
}
resource "kubectl_manifest" "cluster-issuer" {
  validate_schema = false
  yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: ${local.use_lets_encrypt_staging_for_testing} ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
    # Email address used for ACME registration
    email: david.c.allen1971@gmail.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the DNS challenge provider
    solvers:
    - selector:
        dnsZones:
          - 'backbone.parkrunpointsleague.org'
          - 'parkrunpointsleague.org'
      dns01:
        # Valid values are None and Follow
        cnameStrategy: Follow
        route53:
          region: eu-west-1
          accessKeyID:
          hostedZoneID: ${module.dns[0].route53_private_hosted_zone_id}
          secretAccessKeySecretRef:
            name: cert-manager-aws-secret-key
            key: secret-access-key
EOF
  depends_on = [kubectl_manifest.cert-manager-aws-secret-key]
}
resource "kubectl_manifest" "cert-manager-aws-secret-key" {
//resource "kubernetes_secret" "cert-manager-aws-secret-key" {
//  metadata {
//    name = cert-manager-aws-secret-key
//  }
  validate_schema = false
  yaml_body = <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cert-manager-aws-secret-key
  namespace: cert-manager
type: Opaque
stringData:
  secret-access-key: ${local.secrets_primary.data["cert-manager-aws-user.secret-key"]}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# certificate requests and ingress
# ---------------------------------------------------------------------------------------------------------------------
resource "kubectl_manifest" "certificate-kube-backbone" {
  validate_schema = false
  yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kube-backbone-prpl
  namespace: default
spec:
  secretName: kube-backbone-prpl-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: 'kube.backbone.parkrunpointsleague.org'
  dnsNames:
    - 'kube.backbone.parkrunpointsleague.org'
EOF
  depends_on = [kubectl_manifest.cluster-issuer]
}
resource "kubectl_manifest" "ingress-kube-backbone" {
  validate_schema = false
  yaml_body = <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo
  annotations:
    kubernetes.io/ingress.class: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
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
  depends_on = [kubectl_manifest.cluster-issuer]
}


