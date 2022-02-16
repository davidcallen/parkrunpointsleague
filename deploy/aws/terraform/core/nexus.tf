module "nexus" {
  # source      = "git@github.com:davidcallen/terraform-module-nexus.git?ref=1.0.0"
  source          = "../../../../../terraform-modules/terraform-module-aws-nexus"
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
  ha_private_load_balancer = {
    enabled    = false # no major need for private ALB
    arn        = ""
    arn_suffix = ""
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
    disallow_ingress_internal_health_check_from_cidrs = []
    # HACK local.nexus_testing_allowed_public_network_cidrs
  }
  ha_public_load_balancer = {
    enabled    = true
    arn        = "" # module.lb-public.load-balancer.arn
    arn_suffix = "" # module.lb-public.load-balancer.arn_suffix
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
        [var.vpc.cidr_block], # Note we allow complete vpc.cidr_block since we have a public load balancer
      )
    }
    # Dont want customers reaching internal healthcheck page
    disallow_ingress_internal_health_check_from_cidrs = []
    # HACK local.nexus_testing_allowed_public_network_cidrs
  }
  ha_auto_scaling_group = {
    aws_ami_id                     = data.aws_ami.centos-7-nexus[0].id
    health_check_grace_period      = 60  # Time (in seconds) after instance comes into service before checking health
    default_cooldown               = 120 # Start the failover instance quickly
    suspended_processes            = []  # ["Launch", "Terminate", "ReplaceUnhealthy", "HealthCheck"]
    cloudwatch_alarm_sns_topic_arn = module.iam-nexus.nexus-profile.name
    check_efs_asg_max_attempts     = 60
    max_size                       = 1
    min_size                       = 1
    desired_capacity               = 1
    target_group_name_prefix       = "nexus" # Max 20 chars !! due to limitation on length of ASG TargetGroups which need to be unique
  }
  name_suffix                    = ""
  hostname_fqdn                  = "${var.environment.resource_name_prefix}-nexus.${var.environment.name}.${module.global_variables.org_domain_name}"
  route53_enabled                = module.global_variables.route53_enabled
  route53_private_hosted_zone_id = (module.global_variables.route53_enabled) ? aws_route53_zone.private[0].id : ""
  server_listening_port          = 8081         # This is the port that the EC2 will listen on, and that ALB will forward traffic to.
  aws_instance_type              = "t3a.medium" # Nexus needs a minimum of 8GB
  aws_ami_id                     = data.aws_ami.centos-7-nexus[0].id
  aws_ssh_key_name               = aws_key_pair.ssh.key_name
  iam_instance_profile           = module.iam-nexus.nexus-profile.name
  disk_root = {
    encrypted = true
  }
  disk_nexus_home = {
    enabled   = true
    type      = "EFS"
    size      = -1
    encrypted = true
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
  //  #  nexus_config_s3_bucket_name                = "s3://parkrunpointsleague.org-prpl-core-nexus-files"
  //  nexus_config_files = [
  //    {
  //      filename          = "nexus.yaml"
  //      contents_base64   = base64encode(local.nexus_config_file_contents)
  //      contents_md5_hash = md5(local.nexus_config_file_contents)
  //    }
  //  ]
  nexus_admin_user_password_secret_id          = module.nexus-admin-password-secret.secret_id
  nexus_jenkins_user_password_secret_id        = module.nexus-jenkins-password-secret.secret_id
  cloudwatch_enabled                           = true
  cloudwatch_refresh_interval_secs             = 60
  telegraf_enabled                             = module.global_variables.telegraf_enabled
  telegraf_influxdb_url                        = module.global_variables.telegraf_influxdb_url
  telegraf_influxdb_password_secret_id         = "" # module.tick-telegraf-password-secret.secret_id
  telegraf_influxdb_retention_policy           = module.global_variables.telegraf_influxdb_retention_policy
  telegraf_influxdb_https_insecure_skip_verify = module.global_variables.telegraf_influxdb_https_insecure_skip_verify
  global_default_tags                          = module.global_variables.default_tags
  depends_on                                   = [module.iam-nexus]
}

//# ---------------------------------------------------------------------------------------------------------------------
//# Create ssh_key_pair and upload ssh public key from file to there
//#   Requires an ssh key to already exist that was created like "ssh-keygen -f ~/.ssh/prpl-aws/prpl-foobar-ssh-key -t rsa -b 2048 -m pem"
//# Would like to use ECDSA or ED25519, but restricted because :
//#  1) data.tls_public_key only supports RSA and ECDSA
//#  2) EC2 aws_key_pair only supports RSA and ED25519
//# ---------------------------------------------------------------------------------------------------------------------
//data "tls_public_key" "ssh-key-nexus-admin-user" {
//  private_key_pem = file("~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key-nexus-admin")
//}
//resource "aws_key_pair" "ssh-key-nexus-admin-user" {
//  key_name   = "${var.environment.resource_name_prefix}-ssh-key-nexus-admin"
//  public_key = data.tls_public_key.ssh-key-nexus-admin-user.public_key_openssh
//}

# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "nexus" {
  name              = "nexus"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "nexus"
    Application = "nexus"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------------------------------------------------
module "iam-nexus" {
  # source           = "git@github.com:davidcallen/terraform-module-iam-nexus.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-iam-nexus"
  resource_name_prefix    = var.environment.resource_name_prefix
  route53_private_zone_id = aws_route53_zone.private[0].id
  secrets_arns = [
    module.nexus-admin-password-secret.secret_arn,
    module.nexus-jenkins-password-secret.secret_arn
  ]
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-nexus"
    Application     = "nexus"
    ApplicationName = "nexus"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------------------------------------------------
module "nexus-admin-password-secret" {
  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
  name                    = "${var.environment.resource_name_prefix}-nexus-admin-password"
  description             = "Nexus Admin internal user login password"
  recovery_window_in_days = 0 # Force secret deletion to action immediately
  account_id              = var.environment.account_id
  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State and git
  password = local.secrets_primary.data["nexus-admin.password"]
  allowed_iam_user_ids = [
    var.environment.account_id,
    "${data.aws_iam_role.admin.unique_id}:*",
    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
    "${module.iam-nexus.nexus-role.unique_id}:*"
  ]
}
# TODO : Currently need to have same nexus 'jenkins' user password defined twice due to avoiding circular terraform dependancies between ASM and IAM and EC2
module "nexus-jenkins-password-secret" {
  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
  name                    = "${var.environment.resource_name_prefix}-nexus-jenkins-password"
  description             = "Nexus 'jenkins' internal user login password. For getting and publishing artifacts to Nexus from Jenkins."
  recovery_window_in_days = 0 # Force secret deletion to action immediately
  account_id              = var.environment.account_id
  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State and git
  password = local.secrets_primary.data["nexus-jenkins.password"]
  allowed_iam_user_ids = [
    var.environment.account_id,
    "${data.aws_iam_role.admin.unique_id}:*",
    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
    # "${module.iam-jenkins.jenkins-controller-role.unique_id}:*",
    "${module.iam-nexus.nexus-role.unique_id}:*"
  ]
}
//locals {
//  # NOTE : there is a bug in the config-as-code plugin https://issues.nexus.io/browse/JENKINS-61985
//  # The workaround is to ensure that the nexus.template.yaml has this line commented out '# - "myView"'
//  nexus_config_file_contents = templatefile("${path.module}/nexus.template.yaml", {
//    # Note that we pass the key as base64 since jcasc and yaml are awkward and key can easily be mangled by newlines.
//    # We then use the ${decodeBase64:} function in jcasc to decode it during update into nexus.
//    # centos_ssh_private_key_base64         = base64encode(file("~/.ssh/prpl-aws/prpl-core-ssh-key"))
//    centos_ssh_private_key_base64       = base64encode(data.tls_public_key.ssh-key.private_key_pem)
//    # nexus_worker_ssh_private_key_base64 = base64encode(data.tls_public_key.ssh-key-nexus-worker-user.private_key_pem)
//    centos_ssh_public_key_base64        = chomp(data.tls_public_key.ssh-key.public_key_openssh)                   # chomp to remove line endings
//    # nexus_worker_ssh_public_key_base64  = chomp(data.tls_public_key.ssh-key-nexus-worker-user.public_key_openssh) # chomp to remove line endings
//    # subnet_ids                          = join(",", module.vpc.private_subnets)
//  })
//}
output "nexus_aws_instance_private_ip" {
  value = module.nexus.aws_instance_private_ip
}