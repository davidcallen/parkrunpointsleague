# Variable Definitions and defaults.
#
# Only define what is needed in this module
#
variable "aws_region" {
  description = "AWS region to apply terraform to."
  default     = ""
  type        = string
}
variable "aws_zones" {
  description = "AWS zones to apply terraform to. The first zone in the list will be the default for single AZ requirements."
  default     = []
  type        = list(string)
}
variable "aws_zone_preferred_placement_index" {
  description = "The index of the preferred AZ. If this AZ goes offline then change this index to the healthy AZ and terraform apply top move."
  default     = 0
  type        = number
}
variable "org_domain_name" {
  description = "Domain name for organisation e.g. parkrunpointsleague.org"
  default     = ""
  type        = string
}
variable "org_name" {
  description = "Name for organisation e.g. parkrunpointsleague"
  default     = ""
  type        = string
}
variable "org_short_name" {
  description = "Short name for organisation e.g. ta"
  default     = ""
  type        = string
}
# Backbone may be in the AWS Master account or possibly within the Core account
variable "backbone_account_id" {
  description = "The Backbone Account ID for the shared services e.g. 597767386394"
  default     = ""
  type        = string
}
variable "backbone_vpc_cidrs" {
  description = "Backbone account VPC cidr block. Must not overlap with other VPCs in this aws account or others within our organisation."
  type = object({
    cidr_block                  = string
    private_subnets_cidr_blocks = list(string)
    public_subnets_cidr_blocks  = list(string)
  })
  default = {
    cidr_block                  = "",
    private_subnets_cidr_blocks = [],
    public_subnets_cidr_blocks  = []
  }
}
variable "core_account_id" {
  description = "The Core Account ID for the shared services e.g. 228947135432"
  default     = ""
  type        = string
}
variable "core_vpc_cidrs" {
  description = "Core account VPC cidr block. Must not overlap with other VPCs in this aws account or others within our organisation."
  type = object({
    cidr_block                  = string
    private_subnets_cidr_blocks = list(string)
    public_subnets_cidr_blocks  = list(string)
  })
  default = {
    cidr_block                  = "",
    private_subnets_cidr_blocks = [],
    public_subnets_cidr_blocks  = []
  }
}
variable "resource_name_prefix" {
  description = "The AWS Resource Name prefix"
  default     = ""
  type        = string
}
variable "resource_deletion_protection" {
  description = "For some environments  (e.g. Core, Customer/production) want to protect against accidental deletion of resources"
  default     = true
  type        = bool
}
variable "allowed_org_public_network_cidrs" {
  description = "List of the allowed PRPL Public IP addresses to access the AWS resources over the internet."
  default     = []
  type        = list(string)
}
variable "allowed_org_private_network_cidrs" {
  description = "List of the allowed PRPL Private IP addresses to access the AWS resources over the VPN."
  default     = []
  type        = list(string)
}
variable "allowed_org_vpn_cidrs" {
  description = "List of the allowed PRPL VPN CIDRs to access the AWS resources."
  default     = []
  type        = list(string)
}
variable "active_directory_mk_ips" {
  type        = list(string)
  description = "List of IP Addresses of MK Active Directory Servers"
  default     = []
}
variable "active_directory_mk_cidrs" {
  type        = list(string)
  description = "List of CIDRs of MK Active Directory Servers"
  default     = []
}
variable "telegraf_influxdb_cidr" {
  description = "The monitoring InfluxDB CIDR for output from Telegraf Agent"
  default     = ""
  type        = string
}
variable "telegraf_influxdb_url" {
  description = "The monitoring InfluxDB URL for output from Telegraf Agent"
  default     = ""
  type        = string
}
variable "telegraf_influxdb_retention_policy" {
  description = "The metric retention policy for outputing to InfluxDB from Telegraf Agent"
  default     = "autogen"
  type        = string
}
# CAUTION !!!!
#   ONLY CHANGE THIS TO FALSE WHEN NUKING AN ENVIRONMENT (i.e. before doing a "total-global-thermonuclear-warfare" terraform destroy)
variable "debug_prevent_destroy_terraform_state_buckets" {
  description = "ONLY CHANGE THIS TO FALSE WHEN NUKING AN ENVIRONMENT (i.e. before doing a 'total-global-thermonuclear-warfare' terraform destroy)"
  default     = true
  type        = bool
}
variable "default_tags" {
  description = "Default tags"
  default     = {}
  type        = map(string)
}
