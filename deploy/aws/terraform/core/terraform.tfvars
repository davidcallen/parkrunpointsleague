# Variable values (overrides defaults defined in variables.tf)
#
environment = {
  name                                         = "core"
  account_id                                   = "228947135432"
  resource_name_prefix                         = "prpl-core"
  resource_deletion_protection                 = false
  cloudwatch_alarms_sns_emails                 = ["david.c.allen1971@gmail.com"] # ["devops@parkrunpointsleague.org"]
  cloudwatch_log_groups_default_retention_days = 5
  default_tags = {
    Environment = "core"
  }
}

# Temporary cost-savings by remove public subnets (not currently needed) and reduce AZs to 1        #COST-SAVING
//vpc = {
//  cidr_block                    = "10.6.0.0/16"
//  private_subnets_cidr_blocks   = ["10.6.1.0/24", "10.6.2.0/24"]
//  public_subnets_cidr_blocks    = ["10.6.101.0/24", "10.6.102.0/24"]      # TODO : Do we really want public subnets in Core ?
//}
vpc = {
  cidr_block                      = "10.6.0.0/16"
  private_subnets_cidr_blocks     = ["10.6.1.0/24", "10.6.2.0/24"]
  public_subnets_cidr_blocks      = ["10.6.101.0/24", "10.6.102.0/24"] # TODO : Do we really want public subnets in Core ?
  flow_logs_to_s3_enabled         = false
  flow_logs_to_cloudwatch_enabled = false
}
//vpc = {
//  cidr_block                  = "10.6.0.0/16"
//  private_subnets_cidr_blocks = ["10.6.0.0/16"] # Temporary cost-savings by reduce AZs to 1
//  public_subnets_cidr_blocks  = []              # Temporary cost-savings by remove public subnets (not currently needed)
//}
//vpc = {
//  cidr_block                      = "10.6.0.0/16"
//  private_subnets_cidr_blocks     = ["10.6.1.0/24"]   # Temporary cost-savings by reduce AZs to 1     #COST-SAVING
//  public_subnets_cidr_blocks      = ["10.6.101.0/24"] # Temporary cost-savings by reduce AZs to 1     #COST-SAVING
//  flow_logs_to_s3_enabled         = false
//  flow_logs_to_cloudwatch_enabled = false
//}

cross_account_access = {
  accounts = [
    {
      name                        = "backbone"
      account_id                  = "597767386394"
      cidr_block                  = "10.5.0.0/16"
      private_subnets_cidr_blocks = ["10.5.1.0/24", "10.5.2.0/24"]
      public_subnets_cidr_blocks  = ["10.5.101.0/24", "10.5.102.0/24"]
    },
    {
      name                        = "dev"
      account_id                  = "760245709408"
      cidr_block                  = "10.7.0.0/16"
      private_subnets_cidr_blocks = ["10.7.1.0/24", "10.7.2.0/24"]
      public_subnets_cidr_blocks  = ["10.7.101.0/24", "10.7.102.0/24"]
    },
    {
      name                        = "prod"
      account_id                  = "472687107726"
      cidr_block                  = "10.9.0.0/16"
      private_subnets_cidr_blocks = ["10.9.1.0/24", "10.9.2.0/24"]
      public_subnets_cidr_blocks  = ["10.9.101.0/24", "10.9.102.0/24"]
    }
  ]
}

customer_account_access = {
  enabled = true
  type    = "SHARED_TRANSIT_GATEWAY"
  accounts = [
    /* only applies if hosting as SaaS */
  ]
}

amis = {
  ami_name_suffix_encrypted = "-enc"
  name_prefix               = "" # typically either "" or the branch name with a hyphen at the end e.g. "HOST-25-"
  centos6_base = {
    enabled       = false
    use_encrypted = true
  }
  centos7_base = {
    enabled       = true
    use_encrypted = true
  }
  centos7_jenkins_controller = {
    enabled       = true
    use_encrypted = true
  }
  centos7_nexus = {
    enabled       = true
    use_encrypted = true
  }
  centos7_prpl = {
    enabled       = true
    use_encrypted = true
  }
  centos7_prpl_builder = {
    enabled       = false
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
  win_active_directory = {
    enabled       = false
    use_encrypted = true
  }
}

# AWS Accounts (other than Core) that are allowed to be packer builders (to generate AMIs).
# Will have access to certain core facilities like s3 bucket for packer software installer files.
packer_builder_account_ids = [
  /* e.g. if have some Admin Sandpit accounts */
]
# AWS Accounts that are allowed to use AMIs built by Core via packer (in particular encrypted AMIs).
share_amis_with_accounts = [
  {
    name       = "prpl-dev"
    account_id = "760245709408"
  },
  {
    name       = "prpl-staging"
    account_id = "456409217779"
  },
  {
    name       = "prpl-prod"
    account_id = "472687107726"
  }
]

# AWS Accounts that are allowed to use AMIs built by Core via packer in their AutoScalingGroups (in particular encrypted AMIs).
share_amis_with_asgs_in_accounts = [
  {
    name       = "prpl-core"
    account_id = "228947135432"
  },
  {
    name       = "prpl-dev"
    account_id = "760245709408"
  },
//  {
//    name       = "prpl-staging"
//    account_id = "456409217779"
//  },
//  {
//    name       = "prpl-prod"
//    account_id = "472687107726"
//  }
]
route53_testing_mode_enabled = true