# ---------------------------------------------------------------------------------------------------------------------
# Decrypt our Secrets file
# (file was generated using sops tool https://github.com/mozilla/sops)
# ---------------------------------------------------------------------------------------------------------------------
provider "sops" {}
data "sops_file" "primary" {
  source_file = "${path.module}/secrets.encrypted.yml"
}
locals {
  secrets_primary = data.sops_file.primary
}
