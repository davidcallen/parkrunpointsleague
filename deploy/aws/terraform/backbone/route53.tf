# ---------------------------------------------------------------------------------------------------------------------
# Route53 : Hosted Zones for our domain "parkrunpointsleague.org"
# ---------------------------------------------------------------------------------------------------------------------
# Imported the automatically created Zone (upon domain registration) using terraform :
#    terraform-v1.0.11 import aws_route53_zone.public Z05031252J93KZFK3MNHW
resource "aws_route53_zone" "public" {
  count   = (module.global_variables.route53_enabled) ? 1 : 0
  name          = module.global_variables.org_domain_name
  comment       = "HostedZone created by Route53 Registrar"
  force_destroy = false
}
# Note: The NS and SOA are automatically created when the Hosted Zone is created.
#
//# Imported the automatically created NS entry (upon domain registration) using terraform :
//#    terraform import aws_route53_record.ns Z05031252J93KZFK3MNHW_parkrunpointsleague.org_NS
//# Note the record ID is in the form ZONEID_RECORDNAME_TYPE_SET-IDENTIFIER (e.g. Z4KAPRWWNC7JR_dev.example.com_NS_dev), where SET-IDENTIFIER is optional
//resource "aws_route53_record" "ns" {
//  count   = (module.global_variables.route53_enabled) ? 1 : 0
//  zone_id = aws_route53_zone.public[0].zone_id
//  name    = module.global_variables.org_domain_name
//  type    = "NS"
//  ttl     = 172800
//  records = [
//    "${aws_route53_zone.public.name_servers[0]}.",
//    "${aws_route53_zone.public.name_servers[1]}.",
//    "${aws_route53_zone.public.name_servers[2]}.",
//    "${aws_route53_zone.public.name_servers[3]}."
//  ]
//}
//# Imported the automatically created SOA entry (upon domain registration) using terraform :
//#    terraform import aws_route53_record.soa Z05031252J93KZFK3MNHW_parkrunpointsleague.org_SOA
//# Note the record ID is in the form ZONEID_RECORDNAME_TYPE_SET-IDENTIFIER (e.g. Z4KAPRWWNC7JR_dev.example.com_NS_dev), where SET-IDENTIFIER is optional
//resource "aws_route53_record" "soa" {
//  count   = (module.global_variables.route53_enabled) ? 1 : 0
//  zone_id = aws_route53_zone.public[0].zone_id
//  name    = module.global_variables.org_domain_name
//  type    = "SOA"
//  ttl     = 900
//  records = [
//    "${trim(aws_route53_zone.public[0].name_servers[0], ".")}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
//  ]
//}

resource "aws_route53_zone" "private" {
  count   = (module.global_variables.route53_enabled) ? 1 : 0
  name          = "${var.environment.name}.${module.global_variables.org_domain_name}"
  comment       = "Private zone for our VPC"
  force_destroy = true
  # Note: without specifying the vpc association here (below), we get a Public Zone (but wanted a Private one)
  # Hence could not use the resource "aws_route53_zone_association" for this association
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53 Resolver Endpoint : INBOUND
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "dns-endpoint-inbound" {
  count     = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name      = "${module.global_variables.org_short_name}-route53-dns-endpoint-inbound"
  direction = "INBOUND"
  security_group_ids = [
    aws_security_group.dns-endpoint-inbound[0].id
  ]
  # Note that we need to specify ip_address twice. Bit of a cheat to repeat with same subnet (since we currently only have one subnet for cost-savings) #COST-SAVINGS
  dynamic "ip_address" {
    for_each = module.vpc.private_subnets
    content {
      subnet_id = ip_address.value
    }
  }
  tags = merge(module.global_variables.default_tags, var.environment.default_tags)
}
resource "aws_security_group" "dns-endpoint-inbound" {
  count     = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name        = "${module.global_variables.org_short_name}-route53-dns-endpoint-inbound"
  description = "Access to Route53 DNS Resolver Endpoint (Inbound)"
  vpc_id      = module.vpc.vpc_id
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name = "${module.global_variables.org_short_name}-route53-dns-endpoint-inbound"
  })
}
# All ingress to port 53
resource "aws_security_group_rule" "dns-endpoint-inbound-allow-ingress-all" {
  count     = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  type        = "ingress"
  description = "DNS"
  from_port   = 53
  to_port     = 53
  protocol    = "all"
  cidr_blocks = concat(
    [module.vpc.vpc_cidr_block],
    var.cross_account_access.accounts[*].cidr_block,
    module.global_variables.allowed_org_vpn_cidrs
  )
  security_group_id = aws_security_group.dns-endpoint-inbound[0].id
}
# All egress to port 53
resource "aws_security_group_rule" "dns-endpoint-inbound-allow-egress-all" {
  count     = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  type        = "egress"
  description = "DNS"
  from_port   = 53
  to_port     = 53
  protocol    = "all"
  cidr_blocks = concat(
    [module.vpc.vpc_cidr_block],
    var.cross_account_access.accounts[*].cidr_block,
    module.global_variables.allowed_org_vpn_cidrs
  )
  security_group_id = aws_security_group.dns-endpoint-inbound[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53 Resolver Endpoint : OUTBOUND
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "dns-endpoint-outbound" {
  count     = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name      = "${module.global_variables.org_short_name}-route53-dns-endpoint-outbound"
  direction = "OUTBOUND"
  security_group_ids = [
    aws_security_group.dns-endpoint-outbound[0].id
  ]
  # Note that we need to specify ip_address twice. Bit of a cheat to repeat with same subnet (since we currently only have one subnet for cost-savings) #COST-SAVINGS
  dynamic "ip_address" {
    for_each = module.vpc.private_subnets
    content {
      subnet_id = ip_address.value
    }
  }
  tags = merge(module.global_variables.default_tags, var.environment.default_tags)
}
# ---------------------------------------------------------------------------------------------------------------------
# Route53 Resolver Security Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "dns-endpoint-outbound" {
  count       = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name        = "${module.global_variables.org_short_name}-route53-dns-endpoint-outbound"
  description = "Access to Route53 DNS Resolver Endpoint (Outbound)"
  vpc_id      = module.vpc.vpc_id
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name = "${module.global_variables.org_short_name}-route53-dns-endpoint-outbound"
  })
}
# All ingress to port 53
resource "aws_security_group_rule" "dns-endpoint-outbound-allow-ingress-all" {
  count       = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  type        = "ingress"
  description = "DNS"
  from_port   = 53
  to_port     = 53
  protocol    = "all"
  cidr_blocks = concat(
    [module.vpc.vpc_cidr_block],
    var.cross_account_access.accounts[*].cidr_block
  )
  security_group_id = aws_security_group.dns-endpoint-outbound[0].id
}
# All egress to port 53
resource "aws_security_group_rule" "dns-endpoint-outbound-allow-egress-all" {
  count       = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  type        = "egress"
  description = "DNS"
  from_port   = 53
  to_port     = 53
  protocol    = "all"
  cidr_blocks = concat(
    [module.vpc.vpc_cidr_block],
    var.cross_account_access.accounts[*].cidr_block,
    module.global_variables.allowed_org_vpn_cidrs
  )
  security_group_id = aws_security_group.dns-endpoint-outbound[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53 Forwarding Rules
# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_route53_resolver_rule" "backbone" {
//  count   = (module.global_variables.route53_enabled) ? 1 : 0
//  domain_name          = "${var.environment.name}.${module.global_variables.org_domain_name}"
//  name                 = var.environment.name
//  rule_type            = "FORWARD"
//  target_ip {
//    ip = cidrhost(var.vpc.private_subnets_cidr_blocks, 2)
//  }
//  tags = merge(module.global_variables.default_tags, var.environment.default_tags)
//}
//resource "aws_route53_resolver_rule_association" "backbone" {
//  count   = (module.global_variables.route53_enabled) ? 1 : 0
//  name =  "${module.global_variables.org_short_name}-route53-dns-endpoint-outbound"
//  resolver_rule_id = aws_route53_resolver_rule.backbone.id
//  vpc_id           = module.vpc.vpc_id
//}
# Inbound Endpoint Forward "parkrunpointsleague.org" requests to Backbone DNS server
resource "aws_route53_resolver_rule" "aws-cloud" {
  count                = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  domain_name          = module.global_variables.org_domain_name
  name                 = "aws-cloud"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-outbound[0].id
  dynamic "target_ip" {
    for_each = aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
    content {
      ip = target_ip.value.ip
    }
  }
  tags = merge(module.global_variables.default_tags, var.environment.default_tags)
}
//resource "aws_route53_resolver_rule_association" "aws-cloud" {
//  count   = (module.global_variables.route53_enabled) ? 1 : 0
//  name             = "${module.global_variables.org_short_name}-route53-dns-endpoint-inbound"
//  resolver_rule_id = aws_route53_resolver_rule.aws-cloud[0].id
//  vpc_id           = module.vpc.vpc_id
//}
# Outbound EndPoint Forward the on-premise domain names requests to our on-premise DNS server
resource "aws_route53_resolver_rule" "on-premise" {
  count                = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  domain_name          = module.global_variables.on_premise_domain_name
  name                 = "on-premise"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-outbound[0].id
  target_ip {
    ip = module.global_variables.on_premise_dns_server_ip
  }
  tags = merge(module.global_variables.default_tags, var.environment.default_tags)
}
resource "aws_route53_resolver_rule_association" "on-premise" {
  count            = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name             = "${module.global_variables.org_short_name}-route53-dns-endpoint-outbound"
  resolver_rule_id = aws_route53_resolver_rule.on-premise[0].id
  vpc_id           = module.vpc.vpc_id
}
# Share above Route53 resolver rules into our other accounts
module "route53-resolver-rule-inbound-sharing-cross-accounts" {
  count = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  # source                  = "git@github.com:davidcallen/terraform-module-route53-resolver-rules-sharing-cross-accounts.git?ref=1.0.0"
  source                    = "../../../../../terraform-modules/terraform-module-route53-resolver-rules-sharing-cross-accounts"
  name                      = "${var.environment.resource_name_prefix}-route53-resolver-rule-aws-cloud-share"
  route53_resolver_rule_arn = aws_route53_resolver_rule.aws-cloud[0].arn
  share_with_account_ids    = var.cross_account_access.accounts[*].account_id
  default_tags              = merge(module.global_variables.default_tags, var.environment.default_tags)
}
module "route53-resolver-rule-outbound-sharing-cross-accounts" {
  count = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  # source                  = "git@github.com:davidcallen/terraform-module-route53-resolver-rules-sharing-cross-accounts.git?ref=1.0.0"
  source                    = "../../../../../terraform-modules/terraform-module-route53-resolver-rules-sharing-cross-accounts"
  name                      = "${var.environment.resource_name_prefix}-route53-resolver-rule-on-premise-share"
  route53_resolver_rule_arn = aws_route53_resolver_rule.on-premise[0].arn
  share_with_account_ids    = var.cross_account_access.accounts[*].account_id
  default_tags              = merge(module.global_variables.default_tags, var.environment.default_tags)
}

# ---------------------------------------------------------------------------------------------------------------------
# SECOND STAGE : This needs to be run after a creation/change of one (or more) cross-account Private Hosted Zones (in other accounts)
# This Stage will attempt to associate the Backbone VPC with those cross-account Private Hosted Zones.
# Otherwise no DNS resolution from Backbone to cross-account hosted FQDNs
# ---------------------------------------------------------------------------------------------------------------------
locals {
  route53_private_hosted_zone_id_filenames = fileset("${path.module}/..", "*/terraform-output-route53-private-hosted-zone-id")
}
data "local_file" "route53_private_hosted_zone_id_files" {
  for_each = local.route53_private_hosted_zone_id_filenames
  filename = "${path.module}/../${each.value}"
}
module "route53-second-stage" {
  count   = (module.global_variables.route53_enabled) ? 1 : 0
  source                                = "./route53-second-stage"
  backbone_vpc_id                       = module.vpc.vpc_id
  other_account_private_hosted_zone_ids = [for file in data.local_file.route53_private_hosted_zone_id_files : file["content"]]
}
output "route53_inbound_endpoint_ips" {
  value = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address[*].ip : ""
}
output "backbone_vpc_id" {
  value = module.vpc.vpc_id
}
resource "local_file" "backbone_vpc_id" {
  content              = module.vpc.vpc_id
  directory_permission = "660"
  file_permission      = "660"
  filename             = "${path.module}/terraform-output-vpc-id"
}
