terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "= 3.69.0"
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
  }
  required_version = "= 1.0.11"
}
