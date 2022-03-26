#---------------------------------------------------------------------------------------------------------------------
# Run PRPL application in EC2 in single-instance or HighAvailability mode (behind LoadBalancer)
#---------------------------------------------------------------------------------------------------------------------
locals {
  # Test mode (either general public access or a goodlist of Public IPs)
  prpl_testing_mode_disallow_general_public_access = true # Set to false once app has gone live

  prpl_testing_allowed_public_network_cidrs = concat(
    module.global_variables.allowed_org_public_network_cidrs
  )
}
module "prpl" {
  # source      = "git@github.com:davidcallen/terraform-module-aws-prpl.git?ref=1.0.0"
  source          = "../../../../../terraform-modules/terraform-module-aws-prpl"
  aws_region      = module.global_variables.aws_region
  aws_zones       = module.global_variables.aws_zones
  org_short_name  = module.global_variables.org_short_name
  org_domain_name = module.global_variables.org_domain_name
  environment = {
    name                         = var.environment.name # Environment Account IDs are used for giving permissions to those Accounts for resources such as AMIs
    account_id                   = var.environment.account_id
    cidr_block                   = var.vpc.cidr_block
    private_subnets_cidr_blocks  = var.vpc.private_subnets_cidr_blocks
    public_subnets_cidr_blocks   = var.vpc.public_subnets_cidr_blocks
    resource_name_prefix         = var.environment.resource_name_prefix
    resource_deletion_protection = var.environment.resource_deletion_protection
    default_tags                 = var.environment.default_tags
  }
  vpc = {
    vpc_id                      = module.vpc.vpc_id
    cidr_block                  = var.vpc.cidr_block
    private_subnets_cidr_blocks = var.vpc.private_subnets_cidr_blocks
    private_subnets_ids         = module.vpc.private_subnets
    public_subnets_cidr_blocks  = var.vpc.private_subnets_cidr_blocks
    public_subnets_ids          = module.vpc.public_subnets
  }
  ha_high_availability_enabled = false
  ha_public_load_balancer = {
    enabled    = true
    arn        = "" # module.lb-public.load-balancer.arn
    arn_suffix = "" # module.lb-public.load-balancer.arn_suffix
    hostname_fqdn = "prpl.${var.environment.name}.${module.global_variables.org_domain_name}"
    port       = 443
    ssl_cert = {
      use_amazon_provider = true # Has the overhead of needing external DNS verification to activate it
      use_self_signed     = false
    }
    alb_listener_arn      = "" # aws_lb_listener.alb-public-https.arn
    alb_listener_priority = 101
    security_group_id     = "" # module.lb-public.security_group_id
    allowed_ingress_cidrs = {
      https = concat(
      module.global_variables.allowed_org_private_network_cidrs,
      [var.vpc.cidr_block],                           # Note we allow complete vpc.cidr_block since we have a public load balancer
      local.prpl_testing_allowed_public_network_cidrs # Goodlist for IPs
      )
    }
    # Dont want customers reaching internal healthcheck page
    disallow_ingress_internal_health_check_from_cidrs = local.prpl_testing_allowed_public_network_cidrs
  }
  ha_private_load_balancer = {
    enabled    = false # no major need for private ALB
    arn        = ""
    arn_suffix = ""
    hostname_fqdn = "prpl.${var.environment.name}.${module.global_variables.org_domain_name}"
    port       = 443
    ssl_cert = {
      use_amazon_provider = true # Has the overhead of needing external DNS verification to activate it
      use_self_signed     = false
    }
    alb_listener_arn      = ""
    alb_listener_priority = 101
    security_group_id     = ""
    allowed_ingress_cidrs = {
      https = []
    }
    # Dont want customers reaching internal healthcheck page
    disallow_ingress_internal_health_check_from_cidrs = local.prpl_testing_allowed_public_network_cidrs
  }
  ha_auto_scaling_group = {
    aws_ami_id                     = data.aws_ami.centos-7-prpl[0].id
    health_check_grace_period      = 60  # Time (in seconds) after instance comes into service before checking health
    default_cooldown               = 120 # Start the failover instance quickly
    suspended_processes            = []  # ["Launch", "Terminate", "ReplaceUnhealthy", "HealthCheck"]
    cloudwatch_alarm_sns_topic_arn = ""
    check_efs_asg_max_attempts     = 60
    max_size                       = 1
    min_size                       = 1
    desired_capacity               = 1
    target_group_name_prefix       = "prpl" # Max 20 chars !! due to limitation on length of ASG TargetGroups which need to be unique
  }
  name_suffix                       = ""
  hostname_fqdn                     = "${var.environment.resource_name_prefix}-prpl.${var.environment.name}.${module.global_variables.org_domain_name}"
  route53_enabled                   = module.global_variables.route53_enabled
  route53_direct_dns_update_enabled = module.global_variables.route53_direct_dns_update_enabled
  route53_private_hosted_zone_id    = (module.global_variables.route53_enabled) ? module.dns[0].route53_private_hosted_zone_id : ""
  route53_public_hosted_zone_id     = (module.global_variables.route53_enabled) ? module.dns[0].route53_public_subdomain_hosted_zone_id : ""
  server_listening_port             = 8080 # This is the port that the EC2 will listen on, and that ALB will forward traffic to.
  aws_instance_type                 = "t3a.small"
  aws_ami_id                        = data.aws_ami.centos-7-prpl[0].id
  aws_ssh_key_name                  = aws_key_pair.ssh.key_name
  iam_instance_profile              = module.iam-prpl.prpl-profile.name
  disk_root = {
    encrypted = true
  }
  disk_prpl_home = {
    enabled   = true
    type      = "EFS"
    size      = -1
    encrypted = true
  }
  database = {
    # HACK HACK HACK HACK HACK
    type                       = "" # "RDS"
    # HACK HACK HACK HACK HACK
    aws_instance_type          = "db.t3.micro"
    engine                     = "mariadb"
    engine_version             = ""
    db_master_password         = local.secrets_primary.data["prpl-db-admin.password"]
    db_hostname               = "" # Leave blank since using RDS
    db_prpl_database_name      = "PRPL"
    db_prpl_username           = "PRPL_USER"
    db_prpl_password_secret_id = module.prpl-db-admin-password-secret.secret_id
    db_cloudwatch_role_arn     = "" # data.aws_iam_role.cloudwatch-agent.arn    # lookup from module.iam-cloudwatch.cloudwatch-agent-role-arn
    allowed_ingress_cidrs = concat(
      # TODO : restrict below so can only access db from our PRPL instance or a Support Desktop instance within the VPC
      module.global_variables.allowed_org_private_network_cidrs,
      var.cross_account_access.accounts[*].cidr_block,
      [var.vpc.cidr_block]
    )
  }
  allowed_ingress_cidrs = {
    https = concat(
      module.global_variables.allowed_org_private_network_cidrs,
      var.cross_account_access.accounts[*].cidr_block,
      [var.vpc.cidr_block]
    )
    http = concat(
      module.global_variables.allowed_org_private_network_cidrs,
      var.cross_account_access.accounts[*].cidr_block,
      [var.vpc.cidr_block]
    )
    ssh = concat(
      module.global_variables.allowed_org_private_network_cidrs,
      var.cross_account_access.accounts[*].cidr_block,
      var.vpc.private_subnets_cidr_blocks
    )
  }
  allowed_egress_cidrs = {
    http              = ["0.0.0.0/0"] # To allow for yum updates need outbound 80 and 443 to internet traffic (oterhwise would need internal centos,sclo,epel updates mirrors)
    https             = ["0.0.0.0/0"] # To allow for yum updates need outbound 80 and 443 to internet traffic (oterhwise would need internal centos,sclo,epel updates mirrors)
    telegraf_influxdb = [module.global_variables.telegraf_influxdb_cidr]
  }
  prpl_user_ssh_public_key                     = aws_key_pair.ssh-key-prpl-admin-user.public_key
  prpl_db_admin_user_password_secret_id        = module.prpl-db-admin-password-secret.secret_id
  prpl_admin_user_password_secret_id           = module.prpl-admin-password-secret.secret_id
  backups = {
    backup_role_arn = ""
    rds = {
      retention_period         = 10
      window                   = ""
      delete_automated_backups = false
    }
    plans = [
//      {
//        name              = "daily"
//        schedule          = "cron(0 4 ? * MON-FRI *)" # Daily at 4 a.m.
//        start_window      = 480                       # Start within 8 hours
//        completion_window = 541                       # The amount of time AWS Backup attempts a backup before canceling the job and returning an error. (must be at least 60 mins more than start_window)
//        lifecycle = {
//          cold_storage_after = 7   # Days after creation that a recovery point is moved to cold storage.
//          delete_after       = 365 # Days after creation that a recovery point is deleted.
//        }
//      },
//      {
//        name              = "weekly"
//        schedule          = "cron(0 5 ? * 2 *)" # Weekly on Tuesday at 5 a.m.
//        start_window      = 480                 # Start within 8 hours
//        completion_window = 541                 # The amount of time AWS Backup attempts a backup before canceling the job and returning an error. (must be at least 60 mins more than start_window)
//        lifecycle = {
//          cold_storage_after = 7   # Days after creation that a recovery point is moved to cold storage.
//          delete_after       = 365 # Days after creation that a recovery point is deleted.
//        }
//      }
    ]
  }
  cloudwatch_enabled                           = true
  cloudwatch_refresh_interval_secs             = 60
  telegraf_enabled                             = module.global_variables.telegraf_enabled
  telegraf_influxdb_url                        = module.global_variables.telegraf_influxdb_url
  telegraf_influxdb_password_secret_id         = "" # module.tick-telegraf-password-secret.secret_id
  telegraf_influxdb_retention_policy           = module.global_variables.telegraf_influxdb_retention_policy
  telegraf_influxdb_https_insecure_skip_verify = module.global_variables.telegraf_influxdb_https_insecure_skip_verify
  global_default_tags                          = module.global_variables.default_tags
  depends_on                                   = [module.iam-prpl]
}

# ---------------------------------------------------------------------------------------------------------------------
# Create ssh_key_pair and upload ssh public key from file to there
#   Requires an ssh key to already exist that was created like "ssh-keygen -f ~/.ssh/prpl-aws/prpl-foobar-ssh-key -t rsa -b 2048 -m pem"
# Would like to use ECDSA or ED25519, but restricted because :
#  1) data.tls_public_key only supports RSA and ECDSA
#  2) EC2 aws_key_pair only supports RSA and ED25519
# ---------------------------------------------------------------------------------------------------------------------
data "tls_public_key" "ssh-key-prpl-admin-user" {
  private_key_pem = file("~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key-prpl-admin")
}
resource "aws_key_pair" "ssh-key-prpl-admin-user" {
  key_name   = "${var.environment.resource_name_prefix}-ssh-key-prpl-admin"
  public_key = data.tls_public_key.ssh-key-prpl-admin-user.public_key_openssh
}

# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "prpl" {
  name              = "prpl"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "prpl"
    Application = "prpl"
  })
}
//module "cloudwatch_alarms_load_balancer_prpl" {
//  # source = "git@github.com:davidcallen/terraform-module-aws-cloudwatch-alarms-load-balancer.git?ref=2.0.0"
//  source = "../../../../../terraform-modules/terraform-module-aws-cloudwatch-alarms-load-balancer"
//  cloudwatch-alarms = {
//    resource_name_prefix = var.environment.resource_name_prefix
//    load_balancer = {
//      arn  = module.lb-public.load-balancer.arn
//      type = "APPLICATION"
//      name = "elb"
//    }
//    target_group = {
//      arn  = module.prpl.target_group_public_http[0].arn # module.prpl.target_group_prpl[0].arn
//      name = module.global_variables.org_short_name
//    }
//    sns_topic_arn                = module.cloudwatch_alarms_sns_topic.sns_topic.arn # lookup for module.cloudwatch_alarms_sns_topic.sns_topic.arn
//    evaluation_periods           = 5
//    resource_deletion_protection = var.environment.resource_deletion_protection
//    default_tags                 = merge(module.global_variables.default_tags, var.environment.default_tags)
//  }
//}

# ---------------------------------------------------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------------------------------------------------
module "iam-prpl" {
  # source           = "git@github.com:davidcallen/terraform-module-iam-prpl.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-iam-prpl"
  resource_name_prefix    = var.environment.resource_name_prefix
  route53_private_zone_id = module.dns[0].route53_private_hosted_zone_id
  secrets_arns = [
    module.prpl-db-admin-password-secret.secret_arn,
    module.prpl-admin-password-secret.secret_arn
  ]
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-prpl"
    Application     = "prpl"
    ApplicationName = "prpl"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------------------------------------------------
module "prpl-db-admin-password-secret" {
  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
  name                    = "${var.environment.resource_name_prefix}-prpl-admin"
  description             = "PRPL DB Admin user login password"
  recovery_window_in_days = 0 # Force secret deletion to action immediately
  account_id              = var.environment.account_id
  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State
  password = local.secrets_primary.data["prpl-db-admin.password"]
  allowed_iam_user_ids = [
    var.environment.account_id,
    "${data.aws_iam_role.admin.unique_id}:*",
    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
    "${module.iam-prpl.prpl-role.unique_id}:*"
  ]
}
module "prpl-admin-password-secret" {
  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
  name                    = "${var.environment.resource_name_prefix}-prpl-nexus"
  description             = "PRPL 'Admin' internal user login password. For login to application as Admin user."
  recovery_window_in_days = 0 # Force secret deletion to action immediately
  account_id              = var.environment.account_id
  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State
  password = local.secrets_primary.data["prpl-admin.password"]
  allowed_iam_user_ids = [
    var.environment.account_id,
    "${data.aws_iam_role.admin.unique_id}:*",
    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
    "${module.iam-prpl.prpl-role.unique_id}:*",
  ]
}
output "prpl_aws_instance_private_ip" {
  value = module.prpl.aws_instance_private_ip
}
