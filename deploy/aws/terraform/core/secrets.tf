# ---------------------------------------------------------------------------------------------------------------------
# Decrypt our Secrets file
# (file was generated using sops tool https://github.com/mozilla/sops)
# ---------------------------------------------------------------------------------------------------------------------
provider "sops" {}
data "sops_file" "primary" {
  source_file = "${path.module}/secrets.encrypted.json"
  input_type = "raw"
}
locals {
  secrets_primary = yamldecode(data.sops_file.primary.raw)    # file data contents are in yaml format so use "raw" access
}
