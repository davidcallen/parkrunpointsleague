# Chart from here : https://github.com/jtblin/kube2iam/tree/master/charts/kube2iam
resource "helm_release" "kube2iam" {
  name          = "kube2iam"
  namespace     = "kube-system"
  repository    = "https://jtblin.github.io/kube2iam/"
  chart         = "kube2iam"
  wait_for_jobs = true
  values = [
    data.template_file.kube2iam_helm_chart_values.rendered
  ]
}
data "template_file" "kube2iam_helm_chart_values" {
  template = <<EOF
host:
  # For RKE cluster : networking uses Canal (which is calico for intra-node and flannel for inter-node)
  # We need iptables rules injected and the interface of "cali+"
  iptables: true
  interface: cali+
rbac:
  create: true
podSecurityPolicy:
  enabled: true
verbose: true
EOF
}

# Check if cert-manager IAM role working (for route53 access)
resource "kubectl_manifest" "kube2iam-cert-manager-test" {
  validate_schema = false
  yaml_body       = <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: aws-cli
  labels:
    name: aws-cli
  annotations:
    iam.amazonaws.com/role: arn:aws:iam::597767386394:role/prpl-backbone-k8s-kube2iam-cert-manager
spec:
  containers:
  - image: fstab/aws-cli
    # Just spin & wait forever
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 30; done;" ]
    name: aws-cli
EOF
//  command:
//  - "/home/aws/aws/env/bin/aws"
//  - "route53"
//  - "list-resource-record-sets"
//  - "--hosted-zone-id"
//  - "${module.dns[0].route53_public_subdomain_hosted_zone_id}"
  depends_on      = [module.k8s-cert-manager]
}
