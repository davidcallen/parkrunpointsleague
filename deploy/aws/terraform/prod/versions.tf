terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "= 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
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
  }
  required_version = "= 1.0.11"
}