# Variable Definitions and values
#
output "aws_region" {
  value = "eu-west-1"
}
output "aws_zones" {
  value = ["eu-west-1a", "eu-west-1b"]
}
output "aws_zone_preferred_placement_index" {
  value = 0
}
output "org_domain_name" {
  value = "parkrunpointsleague.org"
}
output "org_name" {
  value = "ParkRunPointsLeague"
}
output "org_short_name" {
  value = "prpl"
}
# Backbone may be in the AWS Root account or possibly within the Core account
output "backbone_account_id" {
  value = "597767386394"
}
output "backbone_vpc_cidrs" {
  value = {
    cidr_block                  = "10.5.0.0/16"
    private_subnets_cidr_blocks = ["10.5.0.0/16"]
    public_subnets_cidr_blocks  = [] # Dont need public subnets in backbone
  }
}
output "core_account_id" {
  value = "228947135432"
}
output "core_vpc_cidrs" {
  value = {
    cidr_block                  = "10.6.0.0/16"
    private_subnets_cidr_blocks = ["10.6.1.0/24", "10.6.2.0/24"]
    public_subnets_cidr_blocks  = ["10.6.101.0/24", "10.6.102.0/24"]
  }
}
output "resource_name_prefix" {
  value = "prpl-"
}
output "resource_deletion_protection" {
  value = "true"
}
# Allowed Organisation's Public (over internet) network CIDRs
output "allowed_org_public_network_cidrs" {
  value = [
    "90.250.8.71/32" # Home
  ]
}
# Allowed Organisation's Private (over VPN) network CIDRs.
# This excludes any VPN virtual address space for connected clients - use "allowed_org_vpn_cidrs" for these.
output "allowed_org_private_network_cidrs" {
  value = [
    "192.168.2.0/24" # our on-premise network
  ]
}
output "on_premise_domain_name" {
  value = "idlinux.net"
}
output "on_premise_dns_server_ips" {
  value = ["192.168.2.17"]
}
# Allowed Organisation's VPN CIDRs
output "allowed_org_vpn_cidrs" {
  value = [
    "10.4.0.0/16" # VPN virtual address space for ClientVPN clients
  ]
}
output "active_directory_ips" {
  value = []
}
output "active_directory_cidrs" {
  value = []
}
# DNS Scenario 1 : Route53 only with No Central Directory and Using R53 Endpoints (module=core/dns-route53-only)
//output "route53_enabled" {
//  value = true
//}
//output "route53_direct_dns_update_enabled" {
//  value = true
//}
//output "route53_use_endpoints" {
//  value = true
//}
//output "central_directory_enabled" {
//  value = false
//}
# DNS Scenario : Central Directory (SimpleAD) with Route53 and No R53 Endpoints (module=core/dns-route53-simple-ad-no-endpoints)
output "route53_enabled" {
  value = true
}
output "route53_direct_dns_update_enabled" {
  value = false
}
output "route53_use_endpoints" {
  value = false
}
output "central_directory_enabled" {
  value = true
}

output "telegraf_enabled" {
  value = false
}
output "telegraf_influxdb_cidr" {
  value = "10.6.1.10/32"
}
output "telegraf_influxdb_url" {
  value = "https://10.6.1.10:8086"
}
//# TODO : Move this password into ASM
//output "telegraf_influxdb_password" {
//  value = "3w45sfgd?ad1341dad23#"
//}
output "telegraf_influxdb_retention_policy" {
  value = "autogen"
}
output "telegraf_influxdb_https_insecure_skip_verify" {
  value = "true"
}
output "cloudwatch_log_groups_default_retention_days" {
  value = 30
}
# CAUTION !!!!
#   ONLY CHANGE THIS TO FALSE WHEN NUKING AN ENVIRONMENT (i.e. before doing a "total-global-thermonuclear-warfare" terraform destroy)
output "debug_prevent_destroy_terraform_state_buckets" {
  value = var.debug_prevent_destroy_terraform_state_buckets
}

output "default_tags" {
  value = {
    Organisation = "prpl"
    Customer     = "prpl"
    Terraform    = "true"
  }
}