# ---------------------------------------------------------------------------------------------------------------------
# Kubernetes : deploy the Kubernetes Dashboard on our Kubernetes cluster
# Uses Helm charts
# ---------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "kubernetes-dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}

# Chart from here : https://github.com/kubernetes/dashboard/tree/master/aio/deploy/helm-chart/kubernetes-dashboard
# Note that this will also deploy the Metrics Server
resource "helm_release" "kubernetes-dashboard" {
  name       = "kubernetes-dashboard"
  namespace  = kubernetes_namespace.kubernetes-dashboard.id
  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  set {
    name  = "metricsScraper.enabled"
    value = "true"
  }
  set {
    name  = "metrics-server.enabled"
    value = "true"
  }
}

# Service Account for dashboard usage - with Full control of whole cluster
resource "kubernetes_service_account" "kubernetes-dashboard" {
  metadata {
    name      = "eks-admin"
    namespace = "kube-system"
  }
}
resource "kubernetes_cluster_role_binding" "kubernetes-dashboard" {
  metadata {
    name = "eks-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "eks-admin"
    namespace = "kube-system"
  }
}
