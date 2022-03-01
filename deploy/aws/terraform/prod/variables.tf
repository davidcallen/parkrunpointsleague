variable "environment" {
  description = "Environment details that are associated with the target AWS account"
  type = object({
    name = string # Environment name (as used in account alias via switching roles) e.g. dev, demo, customerX-prod.
    #    Name should be unique within our organistation
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
    route53_enabled                              = false
    route53_use_endpoints                        = false
    default_tags                                 = {}
  }
}
//variable "environments" {
//  description = "List of environment information e.g. account IDs, public/private subnet cidrs"
//  type = list(object({
//    name                        = string
//    # Environment Account IDs are used for giving permissions to those Accounts for resources such as AMIs
//    account_id                  = string
//    cidr_block                  = string
//    private_subnets_cidr_blocks = list(string)
//    public_subnets_cidr_blocks  = list(string)
//  }))
//  default = []
//}

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

variable "customer_account_access" {
  description = "Customer account access"
  type = object({
    # Enable customer account access will result in creation of recpricating Routes and SecurityGroup Rules (limit and selected) between this and customer accounts.
    # Note that SecurityGroup Rules are applied only in selected situations for increased security
    enabled = bool
    # Cross-account access type can be "VPC_PEERING", "SHARED_TRANSIT_GATEWAY"
    type = string
    accounts = list(object({
      name                        = string
      account_id                  = string
      cidr_block                  = string
      private_subnets_cidr_blocks = list(string)
      public_subnets_cidr_blocks  = list(string)
    }))
  })
  default = {
    enabled  = true
    type     = ""
    accounts = []
  }
}

variable "amis" {
  type = object({
    owner_account_id          = string
    owner_account_kms_key_id  = string
    ami_name_suffix_encrypted = string
    name_prefix               = string # typically either "" or the branch name with a hyphen at the end e.g. "HOST-25-"
    centos6_base = object({
      enabled       = bool
      use_encrypted = bool
    })
    centos7_base = object({
      enabled       = bool
      use_encrypted = bool
    })
    centos7_prpl = object({
      enabled       = bool
      use_encrypted = bool
    })
    win_base = object({
      enabled       = bool
      use_encrypted = bool
    })
    win_core_base = object({
      enabled       = bool
      use_encrypted = bool
    })
    win_desktop = object({
      enabled       = bool
      use_encrypted = bool
    })
  })
  default = {
    owner_account_id          = ""
    owner_account_kms_key_id  = ""
    ami_name_suffix_encrypted = "-enc"
    name_prefix               = "" # typically either "" or the branch name with a hyphen at the end e.g.
    centos6_base = {
      enabled       = false
      use_encrypted = true
    }
    centos7_base = {
      enabled       = true
      use_encrypted = true
    }
    centos7_prpl = {
      enabled       = true
      use_encrypted = true
    }
    win_base = {
      enabled       = true
      use_encrypted = true
    }
    win_core_base = {
      enabled       = false
      use_encrypted = true
    }
    win_desktop = {
      enabled       = false
      use_encrypted = true
    }
  }
}

variable "route53_testing_mode_enabled" {
  description = "True if want to test Route53"
  type        = bool
  default     = false
}