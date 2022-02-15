variable "environment" {
  description = "Environment details that are associated with the target AWS account"
  type = object({
    name                                         = string # Environment name (as used in account alias via switching roles) e.g. dev, demo, customerX-prod. Name should be unique within our organisation
    account_id                                   = string # Environment account id
    resource_name_prefix                         = string # AWS Resource Name prefix
    resource_deletion_protection                 = bool   # To protect against accidental deletion of resources
    cloudwatch_alarms_sns_emails                 = list(string)
    cloudwatch_log_groups_default_retention_days = number
    route53_enabled                              = bool
    route53_use_endpoints                        = bool
    default_tags                                 = map(string)
  })
  default = {
    name                                         = ""
    account_id                                   = ""
    resource_name_prefix                         = ""
    resource_deletion_protection                 = true
    cloudwatch_alarms_sns_emails                 = []
    cloudwatch_log_groups_default_retention_days = 10
    route53_enabled                              = false
    route53_use_endpoints                        = false
    default_tags                                 = {}
  }
}
variable "vpc" {
  description = "VPC cidr block. Must not overlap with other VPCs in this aws account or others within our organisation."
  type = object({
    cidr_block                      = string
    private_subnets_cidr_blocks     = list(string)
    public_subnets_cidr_blocks      = list(string)
    flow_logs_to_s3_enabled         = bool
    flow_logs_to_cloudwatch_enabled = bool
  })
  default = {
    cidr_block                      = ""
    private_subnets_cidr_blocks     = []
    public_subnets_cidr_blocks      = []
    flow_logs_to_s3_enabled         = false
    flow_logs_to_cloudwatch_enabled = false
  }
}
variable "cross_account_access" {
  description = "Cross-account access"
  type = object({
    accounts = list(object({
      name                        = string
      account_id                  = string
      cidr_block                  = string
      private_subnets_cidr_blocks = list(string)
      public_subnets_cidr_blocks  = list(string)
    }))
  })
  default = {
    accounts = []
  }
}
variable "us_east_1_tgw_static_routes" {
  description = "List of CIDRS of VPCs in other region that are attached to their TGW that is peered with our regions TGW (Their routes dont auto propogate)."
  type        = list(string)
  default     = []
}
variable "client_vpn" {
  description = ""
  type = object({
    enabled                              = bool
    client_cidr_block                    = string # The cidr block for the connected client's ip address. Ensure this cidr does not overlap with any destination VPC cidrs !
    cloudwatch_logging_enabled           = bool
    cloudwatch_log_groups_retention_days = number
    authorize_account_cidrs              = list(string)
    routing_to_account_cidrs             = list(string)
  })
  default = {
    enabled                              = false
    client_cidr_block                    = ""
    cloudwatch_logging_enabled           = false
    cloudwatch_log_groups_retention_days = 0
    authorize_account_cidrs              = []
    routing_to_account_cidrs             = []
  }
}
