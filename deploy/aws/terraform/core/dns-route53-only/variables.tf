variable "environment" {
  description = "Environment details that are associated with the target AWS account"
  type = object({
    name                                         = string # Environment name (as used in account alias via switching roles) e.g. dev, demo, customerX-prod. Name should be unique within our organisation
    account_id                                   = string # Environment account id
    resource_name_prefix                         = string # AWS Resource Name prefix
    resource_deletion_protection                 = bool   # To protect against accidental deletion of resources
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
    cloudwatch_log_groups_default_retention_days = 10
    default_tags                                 = {}
  }
}
//variable "vpc_id" {
//  description = "The VPC ID"
//  type        = string
//  default     = ""
//}
//variable "vpc_cidr_block" {
//  description = "The VPC CIDR block"
//  type        = string
//  default     = ""
//}
//variable "vpc_private_subnet_ids" {
//  description = "The VPC private subnet IDs list"
//  type        = list(string)
//  default     = []
//}
//variable "vpc_private_subnet_cidrs" {
//  description = "The VPC private subnet CIDRs list"
//  type        = list(string)
//  default     = []
//}
variable "vpc" {
  description = "VPC cidr block. Must not overlap with other VPCs in this aws account or others within our organisation."
  type = object({
    vpc_id                      = string
    cidr_block                  = string
    private_subnets_cidr_blocks = list(string)
    private_subnets_ids         = list(string)
    public_subnets_cidr_blocks  = list(string)
    public_subnets_ids          = list(string)
  })
  default = {
    vpc_id                      = ""
    cidr_block                  = ""
    private_subnets_cidr_blocks = []
    private_subnets_ids         = []
    public_subnets_cidr_blocks  = []
    public_subnets_ids          = []
  }
}
//# Variable Definitions and defaults.
//#
//# Only define what is needed in this module
//#
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
//variable "org_name" {
//  description = "Name for organisation e.g. parkrunpointsleague"
//  default     = ""
//  type        = string
//}
variable "org_short_name" {
  description = "Short name for organisation e.g. prpl"
  default     = ""
  type        = string
}
//# Backbone may be in the AWS Master account or possibly within the Core account
//variable "backbone_account_id" {
//  description = "The Backbone Account ID for the shared services e.g. 597767386394"
//  default     = ""
//  type        = string
//}
//variable "backbone_vpc_cidrs" {
//  description = "Backbone account VPC cidr block. Must not overlap with other VPCs in this aws account or others within our organisation."
//  type = object({
//    cidr_block                  = string
//    private_subnets_cidr_blocks = list(string)
//    public_subnets_cidr_blocks  = list(string)
//  })
//  default = {
//    cidr_block                  = "",
//    private_subnets_cidr_blocks = [],
//    public_subnets_cidr_blocks  = []
//  }
//}
//variable "core_account_id" {
//  description = "The Core Account ID for the shared services e.g. 228947135432"
//  default     = ""
//  type        = string
//}
//variable "core_vpc_cidrs" {
//  description = "Core account VPC cidr block. Must not overlap with other VPCs in this aws account or others within our organisation."
//  type = object({
//    cidr_block                  = string
//    private_subnets_cidr_blocks = list(string)
//    public_subnets_cidr_blocks  = list(string)
//  })
//  default = {
//    cidr_block                  = "",
//    private_subnets_cidr_blocks = [],
//    public_subnets_cidr_blocks  = []
//  }
//}
//variable "resource_name_prefix" {
//  description = "The AWS Resource Name prefix"
//  default     = ""
//  type        = string
//}
//variable "resource_deletion_protection" {
//  description = "For some environments  (e.g. Core, Customer/production) want to protect against accidental deletion of resources"
//  default     = true
//  type        = bool
//}
//variable "allowed_org_public_network_cidrs" {
//  description = "List of the allowed PRPL Public IP addresses to access the AWS resources over the internet."
//  default     = []
//  type        = list(string)
//}
//variable "allowed_org_private_network_cidrs" {
//  description = "List of the allowed PRPL Private IP addresses to access the AWS resources over the VPN."
//  default     = []
//  type        = list(string)
//}
variable "on_premise_domain_name" {
  description = "Our on-premise domain name"
  type        = string
  default     = ""
}
variable "on_premise_dns_server_ips" {
  description = "Our on-premise DNS server IP addresses"
  type        = list(string)
  default     = []
}
//variable "allowed_org_vpn_cidrs" {
//  description = "List of the allowed PRPL VPN CIDRs to access the AWS resources."
//  default     = []
//  type        = list(string)
//}
//variable "active_directory_mk_ips" {
//  type        = list(string)
//  description = "List of IP Addresses of MK Active Directory Servers"
//  default     = []
//}
//variable "active_directory_mk_cidrs" {
//  type        = list(string)
//  description = "List of CIDRs of MK Active Directory Servers"
//  default     = []
//}
//variable "route53_enabled" {
//  description = "Use Route53 for DNS"
//  type        = bool
//  default     = false
//}
variable "route53_use_endpoints" {
  description = "Use Route53 Endpoints for DNS"
  type        = bool
  default     = false
}
variable "route53_testing_mode_enabled" {
  description = "True if want to test Route53"
  type        = bool
  default     = false
}
variable "route53_testing_mode_ami_id" {
  description = "The AMI ID to be used on testing instances"
  type        = string
  default     = ""
}
variable "route53_direct_dns_update_enabled" {
  description = "If using direct add/update of hostname DNS record to Route53"
  default     = false
  type        = bool
}
variable "route53_endpoint_inbound_allow_ingress_cidrs" {
  description = ""
  type        = list(string)
}
variable "route53_endpoint_inbound_allow_egress_cidrs" {
  description = ""
  type        = list(string)
}
variable "route53_endpoint_outbound_allow_ingress_cidrs" {
  description = ""
  type        = list(string)
}
variable "route53_endpoint_outbound_allow_egress_cidrs" {
  description = ""
  type        = list(string)
}
//variable "central_directory_enabled" {
//  description = "True if using a centralised directory like SimpleAD or Full MS Active Directory"
//  type        = bool
//  default     = true
//}
//variable "telegraf_enabled" {
//  description = "True if monitoring with InfluxDB from Telegraf Agent"
//  type        = bool
//  default     = true
//}
//variable "telegraf_influxdb_cidr" {
//  description = "The monitoring InfluxDB CIDR for output from Telegraf Agent"
//  default     = ""
//  type        = string
//}
//variable "telegraf_influxdb_url" {
//  description = "The monitoring InfluxDB URL for output from Telegraf Agent"
//  default     = ""
//  type        = string
//}
//variable "telegraf_influxdb_retention_policy" {
//  description = "The metric retention policy for outputing to InfluxDB from Telegraf Agent"
//  default     = "autogen"
//  type        = string
//}
//variable "telegraf_influxdb_https_insecure_skip_verify" {
//  description = "True if skip SSL/TLS certificate verification on InfluxDB HTTPS endpoint"
//  type        = bool
//  default     = false
//}
//# CAUTION !!!!
//#   ONLY CHANGE THIS TO FALSE WHEN NUKING AN ENVIRONMENT (i.e. before doing a "total-global-thermonuclear-warfare" terraform destroy)
//variable "debug_prevent_destroy_terraform_state_buckets" {
//  description = "ONLY CHANGE THIS TO FALSE WHEN NUKING AN ENVIRONMENT (i.e. before doing a 'total-global-thermonuclear-warfare' terraform destroy)"
//  default     = true
//  type        = bool
//}
variable "default_tags" {
  description = "Default tags"
  default     = {}
  type        = map(string)
}
variable "ec2_ssh_key_pair_name" {
  type = string
}
variable "share_with_account_ids" {
  type = list(string)
}