variable "name" {
  description = "The Name of ECS cluster (and resources)"
  type        = string
  default     = ""
}
variable "org_domain_name" {
  description = "Domain name for organisation e.g. parkrunpointsleague.org"
  default     = ""
  type        = string
}
variable "environment" {
  description = "Environment information e.g. account IDs, public/private subnet cidrs"
  type = object({
    name                                         = string # Environment Account IDs are used for giving permissions to those Accounts for resources such as AMIs
    account_id                                   = string
    resource_name_prefix                         = string # For some environments  (e.g. Core, Customer/production) want to protect against accidental deletion of resources
    resource_deletion_protection                 = bool
    cloudwatch_alarms_sns_emails                 = list(string)
    cloudwatch_log_groups_default_retention_days = number
    default_tags                                 = map(string)
  })
  default = {
    name                                         = ""
    account_id                                   = ""
    resource_name_prefix                         = ""
    resource_deletion_protection                 = true
    cloudwatch_alarms_sns_emails                 = []
    cloudwatch_log_groups_default_retention_days = 5
    default_tags                                 = {}
  }
}
variable "vpc_id" {
  description = "The VPC ID"
  type        = string
  default     = ""
}
variable "vpc_private_subnet_ids" {
  description = "The VPC private subnet IDs list"
  type        = list(string)
  default     = []
}
variable "vpc_private_subnet_cidrs" {
  description = "The VPC private subnet CIDRs list"
  type        = list(string)
  default     = []
}
variable "cluster_ingress_allowed_cidrs" {
  description = "The Cluster ingress allowed CIDRs list"
  type        = list(string)
  default     = []
}
variable "cluster_egress_allowed_cidrs" {
  description = "The Cluster egress allowed CIDRs list"
  type        = list(string)
  default     = []
}
variable "cluster_node_ssh_key_name" {
  description = "The SSH Key name to be installed in each ECS Node VM."
  type        = string
  default     = ""
}
variable "global_default_tags" {
  description = "Global default tags"
  type        = map(string)
  default     = {}
}