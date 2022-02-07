terraform {
  required_providers {
    external = {
      source = "hashicorp/external"
      version = "= 2.1.0"
    }
    null = {
      source = "hashicorp/null"
      version = "= 3.1.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "= 3.1.0"
    }
  }
}
