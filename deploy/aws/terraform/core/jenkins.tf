module "jenkins_controller" {
  # source      = "git@github.com:davidcallen/terraform-module-aws-jenkins-controller.git?ref=1.0.0"
  source          = "../../../../../terraform-modules/terraform-module-aws-jenkins-controller"
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
    # HACK local.jenkins_controller_testing_allowed_public_network_cidrs
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
    # HACK local.jenkins_controller_testing_allowed_public_network_cidrs
  }
  ha_auto_scaling_group = {
    aws_ami_id                     = data.aws_ami.centos-7-jenkins-controller[0].id
    health_check_grace_period      = 60  # Time (in seconds) after instance comes into service before checking health
    default_cooldown               = 120 # Start the failover instance quickly
    suspended_processes            = []  # ["Launch", "Terminate", "ReplaceUnhealthy", "HealthCheck"]
    cloudwatch_alarm_sns_topic_arn = module.iam-jenkins.jenkins-controller-profile.name
    check_efs_asg_max_attempts     = 60
    max_size                       = 1
    min_size                       = 1
    desired_capacity               = 1
    target_group_name_prefix       = "jenkins-controller" # Max 20 chars !! due to limitation on length of ASG TargetGroups which need to be unique
  }
  name_suffix           = ""
  hostname_fqdn         = "jenkins.parkrunpointsleague.org"
  server_listening_port = 8080 # This is the port that the EC2 will listen on, and that ALB will forward traffic to.
  aws_instance_type     = "t3a.small"
  aws_ami_id            = data.aws_ami.centos-7-jenkins-controller[0].id
  aws_ssh_key_name      = aws_key_pair.ssh.key_name
  iam_instance_profile  = module.iam-jenkins.jenkins-controller-profile.name
  disk_root = {
    encrypted = true
  }
  disk_jenkins_home = {
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
    nexus             = [var.vpc.cidr_block]
    telegraf_influxdb = [module.global_variables.telegraf_influxdb_cidr]
  }
  jenkins_user_ssh_public_key   = aws_key_pair.ssh-key-jenkins-admin-user.public_key
  jenkins_worker_ssh_public_key = aws_key_pair.ssh-key-jenkins-worker-user.public_key
  # NOTE : there is a bug in the config-as-code plugin https://issues.jenkins.io/browse/JENKINS-61985
  # The workaround is to ensure that the jenkins.template.yaml has this line commented out '# - "myView"'
  jenkins_config_files = [
    {
      filename          = "jenkins.yaml"
      contents_base64   = base64encode(local.jenkins_config_file_contents)
      contents_md5_hash = md5(local.jenkins_config_file_contents)
    }
  ]
  jenkins_admin_user_password_secret_id        = module.jenkins-controller-admin-password-secret.secret_id
  jenkins_nexus_user_password_secret_id        = module.jenkins-controller-nexus-password-secret.secret_id
  cloudwatch_enabled                           = true
  cloudwatch_refresh_interval_secs             = 60
  telegraf_enabled                             = module.global_variables.telegraf_enabled
  telegraf_influxdb_url                        = module.global_variables.telegraf_influxdb_url
  telegraf_influxdb_password_secret_id         = "" # module.tick-telegraf-password-secret.secret_id
  telegraf_influxdb_retention_policy           = module.global_variables.telegraf_influxdb_retention_policy
  telegraf_influxdb_https_insecure_skip_verify = module.global_variables.telegraf_influxdb_https_insecure_skip_verify
  global_default_tags                          = module.global_variables.default_tags
  depends_on                                   = [module.iam-jenkins]
}

# ---------------------------------------------------------------------------------------------------------------------
# Create ssh_key_pair and upload ssh public key from file to there
#   Requires an ssh key to already exist that was created like "ssh-keygen -f ~/.ssh/prpl-aws/prpl-foobar-ssh-key -t rsa -b 2048 -m pem"
# ---------------------------------------------------------------------------------------------------------------------
data "tls_public_key" "ssh-key-jenkins-admin-user" {
  private_key_pem = file("~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key-jenkins-admin")
}
resource "aws_key_pair" "ssh-key-jenkins-admin-user" {
  key_name   = "${var.environment.resource_name_prefix}-ssh-key-jenkins-admin"
  public_key = data.tls_public_key.ssh-key-jenkins-admin-user.public_key_openssh
}

# ---------------------------------------------------------------------------------------------------------------------
# Create ssh_key_pair and upload ssh public key from file to there
#   Requires an ssh key to already exist that was created like "ssh-keygen -f ~/.ssh/prpl-aws/prpl-foobar-ssh-key -t rsa -b 2048 -m pem"
# ---------------------------------------------------------------------------------------------------------------------
data "tls_public_key" "ssh-key-jenkins-worker-user" {
  private_key_pem = file("~/.ssh/prpl-aws/${var.environment.resource_name_prefix}-ssh-key-jenkins-worker")
}
resource "aws_key_pair" "ssh-key-jenkins-worker-user" {
  key_name   = "${var.environment.resource_name_prefix}-ssh-key-jenkins-worker"
  public_key = data.tls_public_key.ssh-key-jenkins-worker-user.public_key_openssh
}

# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "jenkins-controller" {
  name              = "jenkins-controller"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "jenkins-controller"
    Application = "jenkins-controller"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------------------------------------------------
module "iam-jenkins" {
  # source           = "git@github.com:davidcallen/terraform-module-iam-jenkins.git?ref=1.0.0"
  source               = "../../../../../terraform-modules/terraform-module-iam-jenkins"
  resource_name_prefix = var.environment.resource_name_prefix
  secrets_arns = [
    module.jenkins-controller-admin-password-secret.secret_arn,
    module.jenkins-controller-nexus-password-secret.secret_arn
  ]
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name            = "${var.environment.resource_name_prefix}-jenkins"
    Application     = "jenkins"
    ApplicationName = "jenkins"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------------------------------------------------
module "jenkins-controller-admin-password-secret" {
  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
  name                    = "${var.environment.resource_name_prefix}-jenkins-controller-admin"
  description             = "Jenkins Admin internal user login password"
  recovery_window_in_days = 0 # Force secret deletion to action immediately
  account_id              = var.environment.account_id
  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State
  password = local.secrets_primary.jenkins-admin.password
  allowed_iam_user_ids = [
    var.environment.account_id,
    "${data.aws_iam_role.admin.unique_id}:*",
    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
    "${module.iam-jenkins.jenkins-controller-role.unique_id}:*"
  ]
}
# TODO : Currently need to have same nexus 'jenkins' user password defined twice due to avoiding circular terraform dependancies between ASM and IAM and EC2
module "jenkins-controller-nexus-password-secret" {
  # source              = "git@github.com:davidcallen/terraform-module-aws-asm-secret.git?ref=1.0.0"
  source                  = "../../../../../terraform-modules/terraform-module-aws-asm-secret"
  name                    = "${var.environment.resource_name_prefix}-jenkins-controller-nexus"
  description             = "Jenkins 'Nexus' internal user login password. For getting and publishing artifacts to Nexus."
  recovery_window_in_days = 0 # Force secret deletion to action immediately
  account_id              = var.environment.account_id
  # TODO : at some point ASM may support the generation of a random password which would be preferable for keeping password out of TF State
  password = local.secrets_primary.jenkins-nexus.password
  allowed_iam_user_ids = [
    var.environment.account_id,
    "${data.aws_iam_role.admin.unique_id}:*",
    "${data.aws_iam_role.OrganizationAccountAccessRole.unique_id}:*",
    "${module.iam-jenkins.jenkins-controller-role.unique_id}:*",
    //    "${module.iam-nexus.nexus-role.unique_id}:*"
  ]
}
locals {
  # NOTE : there is a bug in the config-as-code plugin https://issues.jenkins.io/browse/JENKINS-61985
  # The workaround is to ensure that the jenkins.template.yaml has this line commented out '# - "myView"'
  jenkins_config_file_contents = templatefile("${path.module}/jenkins.template.yaml", {
    # Note that we pass the key as base64 since jcasc and yaml are awkward and key can easily be mangled by newlines.
    # We then use the ${decodeBase64:} function in jcasc to decode it during update into jenkins.
    # centos_ssh_private_key_base64         = base64encode(file("~/.ssh/prpl-aws/prpl-core-ssh-key"))
    centos_ssh_private_key_base64         = base64encode(data.tls_public_key.ssh-key.private_key_pem)
    jenkins_worker_ssh_private_key_base64 = base64encode(data.tls_public_key.ssh-key-jenkins-worker-user.private_key_pem)
    centos_ssh_public_key_base64          = chomp(data.tls_public_key.ssh-key.public_key_openssh)                     # chomp to remove line endings
    jenkins_worker_ssh_public_key_base64  = chomp(data.tls_public_key.ssh-key-jenkins-worker-user.public_key_openssh) # chomp to remove line endings
    subnet_ids                            = join(",", module.vpc.private_subnets)
    jenkins_url                           = "http://prpl-core-jenkins:8080"
    jenkins_listening_port                = 8080
    nexus_host                            = module.nexus.aws_instance_private_ip
    nexus_http_port                       = 8081
    nexus_http_protocol                   = "http"
  })
}
output "jenkins_aws_instance_private_ip" {
  value = module.jenkins_controller.aws_instance_private_ip
}