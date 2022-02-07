# Variable Definitions and defaults.
#
# Only define what is needed in this module
#
# Backbone may be in the AWS Master account or possibly within the Core account
variable "backbone_account_id" {
  description = "The Backbone Account ID for the shared services e.g. 597767386394"
  default     = ""
  type        = string
}
variable "environment" {
  description = "Environment information e.g. account IDs, public/private subnet cidrs"
  type = object({
    name                          = string
    # Environment Account IDs are used for giving permissions to those Accounts for resources such as AMIs
    account_id                    = string
    resource_name_prefix          = string
    # For some environments  (e.g. Core, Customer/production) want to protect against accidental deletion of resources
    resource_deletion_protection  = bool
    default_tags                  = map(string)
  })
  default = {
    name                          = ""
    account_id                    = ""
    resource_name_prefix          = ""
    resource_deletion_protection  = true
    default_tags                  = {}
  }
}
variable "org_domain_name" {
  description = "Domain name for organisation e.g. parkrunpointsleague.org"
  default     = ""
  type        = string
}
variable "org_name" {
  description = "Name for organisation e.g. parkrunpointsleague"
  default     = ""
  type 		  = string
}
variable "org_short_name" {
  description = "Short name for organisation e.g. ta"
  default     = ""
  type 		  = string
}
variable "share_amis_with_accounts" {
  description = "AWS Accounts that are allowed to use AMIs built by Core via packer (in particular encrypted AMIs)."
  type = list(object({
    name                        = string
    account_id                  = string
  }))
  default     = []
}
variable "share_amis_with_asgs_in_accounts" {
  description = "AWS Accounts that are allowed to use AMIs built by Core via packer in their AutoScalingGroups (in particular encrypted AMIs)."
  type = list(object({
    name                        = string
    account_id                  = string
  }))
  default     = []
}
variable "packer_builder_account_ids" {
  description = "AWS Accounts that are allowed to be packer builders (to generate AMIs). Will have access to certain core facilities like s3 bucket for packer software installer files."
  default     = []
  type        = list(string)
}
variable "vpc_id" {
  description = "The VPC id"
  type        = string
  default     = ""
}
variable "allowed_ingress_cidrs_ssh" {
  description = "The allowed ingress CIDR blocks for SSH service"
  type        = list(string)
  default     = []
}
variable "allowed_ingress_cidrs_rdp" {
  description = "The allowed ingress CIDR blocks for RDP service"
  type        = list(string)
  default     = []
}
variable "allowed_ingress_cidrs_winrm" {
  description = "The allowed ingress CIDR blocks for WinRM service"
  type        = list(string)
  default     = []
}
variable "global_default_tags" {
  description   = "Global default tags"
  default       = {}
  type          = map(string)
}