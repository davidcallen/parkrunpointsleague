terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "= 4.4.0"
    }
    external = {
      source = "hashicorp/external"
      version = "= 2.1.0"
    }
    null = {
      source = "hashicorp/null"
      version = "= 3.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 3.1.0"
    }
    sops = {
      source = "carlpett/sops"
      version = "= 0.6.3"
    }
    local = {
      source = "hashicorp/local"
      version = "= 2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.4.1"
    }
    rke = {
      source  = "rancher/rke"
      version = "= 1.3.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "1.22.2"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "1.0.1"
    }
  }
  required_version = "= 1.0.11"
}
