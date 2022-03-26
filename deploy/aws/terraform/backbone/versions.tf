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
  }
  required_version = "= 1.0.11"
}
