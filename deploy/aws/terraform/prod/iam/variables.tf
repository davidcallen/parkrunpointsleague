# Variable Definitions and defaults.
#
# Only define what is needed in this module
#
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
# Backbone may be in the AWS Master account or possibly within the Core account
variable "backbone_account_id" {
  description = "The Backbone Account ID for the shared services e.g. 597767386394"
  default     = ""
  type        = string
}
variable "global_default_tags" {
  description   = "Global default tags"
  default       = {}
  type          = map(string)
}