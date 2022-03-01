module "simple-ad-admin-linux" {
  # source      = "git@github.com:davidcallen/terraform-module-simple-ad-admin-linux.git?ref=1.0.0"
  source          = "../../../../../../terraform-modules/terraform-module-aws-simple-ad-admin-linux"
  aws_region      = var.aws_region
  aws_zones       = var.aws_zones
  org_short_name  = var.org_short_name
  org_domain_name = var.org_domain_name
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
    vpc_id                      = var.vpc.vpc_id
    cidr_block                  = var.vpc.cidr_block
    private_subnets_cidr_blocks = var.vpc.private_subnets_cidr_blocks
    private_subnets_ids         = var.vpc.private_subnets_ids
    public_subnets_cidr_blocks  = var.vpc.private_subnets_cidr_blocks
    public_subnets_ids          = var.vpc.public_subnets_ids
  }
  name_suffix                       = ""
  # hostname_fqdn                     = "${var.environment.resource_name_prefix}-simple-ad-admin-linux.${var.environment.name}.${var.org_domain_name}"
  hostname_fqdn                     = (var.org_using_subdomains) ? "${var.environment.resource_name_prefix}-simple-ad-admin-linux.${var.environment.name}.${var.org_domain_name}" : "${var.environment.resource_name_prefix}-simple-ad-admin-linux.${var.org_domain_name}"
  route53_enabled                   = true
  route53_direct_dns_update_enabled = false
  route53_private_hosted_zone_id    = data.local_file.backbone_phz_id_file.content # aws_route53_zone.private.id

  # domain_name                 = "${var.environment.name}.${var.org_domain_name}"
  domain_name                 = var.org_domain_name
  domain_netbios_name         = upper(var.org_short_name)
  domain_join_user_name       = "Administrator"                                             # var.active_directory_domain_join_user_name
  domain_join_user_password   = var.central_directory_admin_password                        # var.active_directory_domain_join_user_password    # TODO : move to Vault
  domain_login_allowed_users  = []                                                          # ["david"]
  domain_login_allowed_groups = ["Domain Users"]                                            # ["CloudAdmins"]
  domain_security_group_ids   = [module.ad-security-group-for-linux.security_group_id]

  aws_instance_type    = "t3a.nano"
  aws_ami_id           = var.central_directory_admin_ami_id_linux
  aws_ssh_key_name     = var.ec2_ssh_key_pair_name
  iam_instance_profile = module.iam-simple-ad-admin.simple_ad_admin_profile.name
  disk_root = {
    encrypted = true
  }
  disk_simple_ad_admin_home = {
    enabled   = true
    type      = "EFS"
    size      = -1
    encrypted = true
  }
  allowed_ingress_cidrs = {
    ssh = var.allowed_ingress_cidrs.ssh
  }
  allowed_egress_cidrs = {
    http              = ["0.0.0.0/0"] # To allow for yum updates need outbound 80 and 443 to internet traffic (oterhwise would need internal centos,sclo,epel updates mirrors)
    https             = ["0.0.0.0/0"] # To allow for yum updates need outbound 80 and 443 to internet traffic (oterhwise would need internal centos,sclo,epel updates mirrors)
    telegraf_influxdb = [var.telegraf_influxdb_cidr]
  }
  //  #  nexus_config_s3_bucket_name                = "s3://parkrunpointsleague.org-prpl-core-nexus-files"
  //  nexus_config_files = [
  //    {
  //      filename          = "nexus.yaml"
  //      contents_base64   = base64encode(local.nexus_config_file_contents)
  //      contents_md5_hash = md5(local.nexus_config_file_contents)
  //    }
  //  ]
#  simple_ad_admin_user_password_secret_id      = module.simple-ad-admin-password-secret.secret_id
  cloudwatch_enabled                           = true
  cloudwatch_refresh_interval_secs             = 60
  telegraf_enabled                             = var.telegraf_enabled
  telegraf_influxdb_url                        = var.telegraf_influxdb_url
  telegraf_influxdb_password_secret_id         = "" # module.tick-telegraf-password-secret.secret_id
  telegraf_influxdb_retention_policy           = var.telegraf_influxdb_retention_policy
  telegraf_influxdb_https_insecure_skip_verify = var.telegraf_influxdb_https_insecure_skip_verify
  global_default_tags                          = var.default_tags
  depends_on                                   = [module.iam-simple-ad-admin]
}

# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "simple-ad-admin" {
  name              = "simple-ad-admin"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(var.default_tags, var.environment.default_tags, {
    Name        = "simple-ad-admin"
    Application = "simple-ad-admin"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------------------------------------------------
module "iam-simple-ad-admin" {
  # source           = "git@github.com:davidcallen/terraform-module-iam-simple-ad-admin.git?ref=1.0.0"
  source                  = "../../../../../../terraform-modules/terraform-module-iam-simple-ad-admin"
  resource_name_prefix    = var.environment.resource_name_prefix
  route53_private_zone_id = data.local_file.backbone_phz_id_file.content #  aws_route53_zone.private.id
  secrets_arns = [
    module.simple-ad-admin-password-secret.secret_arn,
  ]
  tags = merge(var.default_tags, var.environment.default_tags, {
    Name        = "${var.environment.resource_name_prefix}-simple-ad-admin"
    Application = "simple-ad"
  })
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
//    # subnet_ids                          = join(",", var.vpc.private_subnets)
//  })
//}
output "simple_ad_admin_linux_aws_instance_private_ip" {
  value = module.simple-ad-admin-linux.aws_instance_private_ip
}