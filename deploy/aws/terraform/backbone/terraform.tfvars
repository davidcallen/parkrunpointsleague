# Variable values (overrides defaults defined in variables.tf)
#
environment = {
  name                                         = "backbone"
  account_id                                   = "597767386394"
  resource_name_prefix                         = "prpl-backbone"
  resource_deletion_protection                 = false
  cloudwatch_alarms_sns_emails                 = ["david.c.allen1971@gmail.com"] # ["devops@parkrunpointsleague.org"]
  cloudwatch_log_groups_default_retention_days = 5
  default_tags = {
    Environment = "backbone"
  }
}

# Need a VPC in Backbone only for because Client VPN requires association to a VPN (cannot attach directly to a TGW - unlike Site-to-Site VPNs).
vpc = {
  cidr_block = "10.5.0.0/16"
  # For cost-savings we are using a single subnet and no public subnets
  # IMPORTANT : If changing this then search terraform for "#COST-SAVINGS" for additional impact

  # private_subnets_cidr_blocks = ["10.5.1.0/24"] # , "10.5.2.0/24"]
  # public_subnets_cidr_blocks  = []              # Dont need public subnets in backbone       #COST-SAVING

  # For Route53 with EndPoints need 2 subnets. Same for AD.
  private_subnets_cidr_blocks = ["10.5.1.0/24", "10.5.2.0/24"] # Need 2 subnets because Route53 Endpoints require it
  public_subnets_cidr_blocks  = ["10.5.101.0/24", "10.5.102.0/24"]

  flow_logs_to_s3_enabled         = false
  flow_logs_to_cloudwatch_enabled = false
}

cross_account_access = {
  accounts = [
    {
      name                        = "core"
      account_id                  = "228947135432"
      cidr_block                  = "10.6.0.0/16"
      private_subnets_cidr_blocks = ["10.6.1.0/24", "10.6.2.0/24"]
      public_subnets_cidr_blocks  = ["10.6.101.0/24", "10.6.102.0/24"]
    },
    {
      name                        = "dev"          # Environment Account IDs are used for giving permissions to those Accounts for resources such as AMIs
      account_id                  = "760245709408" # These cidrs are needed to setup SecurityGroup rules, and routes for cross-account access.
      cidr_block                  = "10.7.0.0/16"
      private_subnets_cidr_blocks = ["10.7.1.0/24", "10.7.2.0/24"]
      public_subnets_cidr_blocks  = ["10.7.101.0/24", "10.7.102.0/24"]
    }
  ]
}
# List of CIDRS of VPCs in other region that are attached to their TGW that is peered with our regions TGW (Their routes dont auto propogate).
us_east_1_tgw_static_routes = [
  /* add cidrs to be routed to TGW in other region */
]
client_vpn = {
  enabled                              = true
  client_cidr_block                    = "10.4.0.0/16"
  cloudwatch_logging_enabled           = true
  cloudwatch_log_groups_retention_days = 1
  authorize_account_cidrs = [
    "10.5.0.0/16", # backbone
    "10.6.0.0/16", # core
    "10.7.0.0/16"  # dev
  ]
  routing_to_account_cidrs = [
    # "10.5.0.0/16", # backbone not needed since this VPC already associated to Client VPN
    "10.6.0.0/16", # core
    "10.7.0.0/16"  # dev
  ]
}
route53_testing_mode_enabled = true
