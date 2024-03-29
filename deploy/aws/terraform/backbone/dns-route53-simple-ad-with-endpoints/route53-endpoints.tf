
# ---------------------------------------------------------------------------------------------------------------------
# Route53 Resolver Endpoint : INBOUND
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "dns-endpoint-inbound" {
  count     = (var.route53_use_endpoints) ? 1 : 0
  name      = "${var.org_short_name}-route53-dns-endpoint-inbound"
  direction = "INBOUND"
  security_group_ids = [
    aws_security_group.dns-endpoint-inbound[0].id
  ]
  # Note that we need to specify ip_address twice. Bit of a cheat to repeat with same subnet (since we currently only have one subnet for cost-savings) #COST-SAVINGS
  dynamic "ip_address" {
    for_each = var.vpc.private_subnets_ids
    content {
      subnet_id = ip_address.value
    }
  }
  tags = merge(var.default_tags, var.environment.default_tags)
}
resource "aws_security_group" "dns-endpoint-inbound" {
  count       = (var.route53_use_endpoints) ? 1 : 0
  name        = "${var.org_short_name}-route53-dns-endpoint-inbound"
  description = "Access to Route53 DNS Resolver Endpoint (Inbound)"
  vpc_id      = var.vpc.vpc_id
  tags = merge(var.default_tags, var.environment.default_tags, {
    Name = "${var.org_short_name}-route53-dns-endpoint-inbound"
  })
}
# All ingress to port 53
resource "aws_security_group_rule" "dns-endpoint-inbound-allow-ingress-all" {
  count             = (var.route53_use_endpoints) ? 1 : 0
  type              = "ingress"
  description       = "DNS"
  from_port         = 53
  to_port           = 53
  protocol          = "all"
  cidr_blocks       = var.route53_endpoint_inbound_allow_ingress_cidrs
  security_group_id = aws_security_group.dns-endpoint-inbound[0].id
}
# All egress to port 53
resource "aws_security_group_rule" "dns-endpoint-inbound-allow-egress-all" {
  count             = (var.route53_use_endpoints) ? 1 : 0
  type              = "egress"
  description       = "DNS"
  from_port         = 53
  to_port           = 53
  protocol          = "all"
  cidr_blocks       = var.route53_endpoint_inbound_allow_egress_cidrs
  security_group_id = aws_security_group.dns-endpoint-inbound[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53 Resolver Endpoint : OUTBOUND
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "dns-endpoint-outbound" {
  count     = (var.route53_use_endpoints) ? 1 : 0
  name      = "${var.org_short_name}-route53-dns-endpoint-outbound"
  direction = "OUTBOUND"
  security_group_ids = [
    aws_security_group.dns-endpoint-outbound[0].id
  ]
  # Note that we need to specify ip_address twice. Bit of a cheat to repeat with same subnet (since we currently only have one subnet for cost-savings) #COST-SAVINGS
  dynamic "ip_address" {
    for_each = var.vpc.private_subnets_ids
    content {
      subnet_id = ip_address.value
    }
  }
  tags = merge(var.default_tags, var.environment.default_tags)
}
# ---------------------------------------------------------------------------------------------------------------------
# Route53 Resolver Security Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "dns-endpoint-outbound" {
  count       = (var.route53_use_endpoints) ? 1 : 0
  name        = "${var.org_short_name}-route53-dns-endpoint-outbound"
  description = "Access to Route53 DNS Resolver Endpoint (Outbound)"
  vpc_id      = var.vpc.vpc_id
  tags = merge(var.default_tags, var.environment.default_tags, {
    Name = "${var.org_short_name}-route53-dns-endpoint-outbound"
  })
}
# All ingress to port 53
resource "aws_security_group_rule" "dns-endpoint-outbound-allow-ingress-all" {
  count             = (var.route53_use_endpoints) ? 1 : 0
  type              = "ingress"
  description       = "DNS"
  from_port         = 53
  to_port           = 53
  protocol          = "all"
  cidr_blocks       = var.route53_endpoint_outbound_allow_ingress_cidrs
  security_group_id = aws_security_group.dns-endpoint-outbound[0].id
}
# All egress to port 53
resource "aws_security_group_rule" "dns-endpoint-outbound-allow-egress-all" {
  count             = (var.route53_use_endpoints) ? 1 : 0
  type              = "egress"
  description       = "DNS"
  from_port         = 53
  to_port           = 53
  protocol          = "all"
  cidr_blocks       = var.route53_endpoint_outbound_allow_egress_cidrs
  security_group_id = aws_security_group.dns-endpoint-outbound[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53 Forwarding Rules : Inbound
# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_route53_resolver_rule" "backbone" {
//  domain_name          = "${var.environment.name}.${var.org_domain_name}"
//  name                 = var.environment.name
//  rule_type            = "FORWARD"
//  target_ip {
//    ip = cidrhost(var.vpc.private_subnets_cidr_blocks, 2)
//  }
//  tags = merge(var.default_tags, var.environment.default_tags)
//}
//resource "aws_route53_resolver_rule_association" "backbone" {
//  name =  "${var.org_short_name}-route53-dns-endpoint-outbound"
//  resolver_rule_id = aws_route53_resolver_rule.backbone.id
//  vpc_id           = var.vpc.vpc_id
//}
# Inbound Endpoint Forward TLD requests to Backbone DNS server
//resource "aws_route53_resolver_rule" "aws-cloud-inbound-endpoint-to-internal-dns" {
//  count                = (var.route53_use_endpoints) ? 1 : 0
//  domain_name          = var.org_domain_name
//  name                 = "aws-cloud-inbound-endpoint-to-internal-dns"
//  rule_type            = "FORWARD"
//  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-inbound[0].id
//  dynamic "target_ip" {
//    for_each = aws_directory_service_directory.simple-directory.dns_ip_addresses
//    content {
//      ip = target_ip.value
//    }
//  }
//  tags = merge(var.default_tags, var.environment.default_tags)
//}


# ---------------------------------------------------------------------------------------------------------------------
# Route53 Forwarding Rules : Outbound
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_resolver_rule" "aws-cloud-outbound-endpoint-to-internal-dns" {
  count                = (var.route53_use_endpoints) ? 1 : 0
  domain_name          = var.org_domain_name
  name                 = "aws-cloud-outbound-endpoint-to-internal-dns"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-outbound[0].id
  dynamic "target_ip" {
    for_each = aws_directory_service_directory.simple-directory.dns_ip_addresses
    content {
      ip = target_ip.value
    }
  }
  tags = merge(var.default_tags, var.environment.default_tags)
}
resource "aws_route53_resolver_rule_association" "aws-cloud-outbound-endpoint-to-internal-dns" {
  name             = "${var.org_short_name}-aws-cloud-outbound-endpoint-to-internal-dns"
  resolver_rule_id = aws_route53_resolver_rule.aws-cloud-outbound-endpoint-to-internal-dns[0].id
  vpc_id           = var.vpc.vpc_id
}
# Outbound Endpoint Forward TLD requests to our Inbound Endpoint which in turn will fwd to our SimpleAD.
//resource "aws_route53_resolver_rule" "aws-cloud-outbound-endpoint-to-inbound-endpoint" {
//  count                = (var.route53_use_endpoints) ? 1 : 0
//  domain_name          = var.org_domain_name
//  name                 = "aws-cloud-outbound-endpoint-to-inbound-endpoint"
//  rule_type            = "FORWARD"
//  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-outbound[0].id
//  dynamic "target_ip" {
//    # for_each = aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
//    #     for_each = (module.global_variables.central_directory_enabled) ? toset([{ip = "10.6.1.209"}, {ip = "10.6.2.43"}]) : aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
//    content {
//      ip = target_ip.value.ip
//    }
//  }
//  tags = merge(var.default_tags, var.environment.default_tags)
//}
//resource "aws_route53_resolver_rule_association" "aws-cloud-outbound-endpoint-to-inbound-endpoint" {
//  name             = "${var.org_short_name}-aws-cloud-outbound-endpoint-to-inbound-endpoint"
//  resolver_rule_id = aws_route53_resolver_rule.aws-cloud-outbound-endpoint-to-inbound-endpoint[0].id
//  vpc_id           = var.vpc.vpc_id
//}
# Outbound EndPoint Forward the on-premise domain names requests to our on-premise DNS server
resource "aws_route53_resolver_rule" "on-premise-to-outbound-endpoint" {
  count                = (var.route53_use_endpoints) ? 1 : 0
  domain_name          = var.on_premise_domain_name
  name                 = "on-premise-to-outbound-endpoint"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-outbound[0].id
  dynamic "target_ip" {
    for_each = var.on_premise_dns_server_ips
    content {
      ip = target_ip.value
    }
  }
  tags = merge(var.default_tags, var.environment.default_tags)
}
resource "aws_route53_resolver_rule_association" "on-premise-outbound-endpoint" {
  count            = (var.route53_use_endpoints) ? 1 : 0
  name             = "${var.org_short_name}-route53-dns-endpoint-outbound"
  resolver_rule_id = aws_route53_resolver_rule.on-premise-to-outbound-endpoint[0].id
  vpc_id           = var.vpc.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53 Forwarding Rules : Sharing with other accounts
# ---------------------------------------------------------------------------------------------------------------------
module "route53-resolver-rule-outbound-endpoint-to-internal-dns-sharing-cross-accounts" {
  count = (var.route53_use_endpoints) ? 1 : 0
  # source                  = "git@github.com:davidcallen/terraform-module-route53-resolver-rules-sharing-cross-accounts.git?ref=1.0.0"
  source                    = "../../../../../../terraform-modules/terraform-module-route53-resolver-rules-sharing-cross-accounts"
  name                      = "${var.environment.resource_name_prefix}-route53-resolver-rule-aws-cloud-share"
  route53_resolver_rule_arn = aws_route53_resolver_rule.aws-cloud-outbound-endpoint-to-internal-dns[0].arn
  share_with_account_ids    = var.share_with_account_ids
  default_tags              = merge(var.default_tags, var.environment.default_tags)
}
//module "route53-resolver-rule-outbound-endpoint-to-inbound-endpoint-sharing-cross-accounts" {
//  count = (var.route53_use_endpoints) ? 1 : 0
//  # source                  = "git@github.com:davidcallen/terraform-module-route53-resolver-rules-sharing-cross-accounts.git?ref=1.0.0"
//  source                    = "../../../../../../terraform-modules/terraform-module-route53-resolver-rules-sharing-cross-accounts"
//  name                      = "${var.environment.resource_name_prefix}-route53-resolver-rule-aws-cloud-share"
//  route53_resolver_rule_arn = aws_route53_resolver_rule.aws-cloud-outbound-endpoint-to-inbound-endpoint[0].arn
//  share_with_account_ids    = var.share_with_account_ids
//  default_tags              = merge(var.default_tags, var.environment.default_tags)
//}
module "route53-resolver-rule-outbound-to-on-premise-sharing-cross-accounts" {
  count = (var.route53_use_endpoints) ? 1 : 0
  # source                  = "git@github.com:davidcallen/terraform-module-route53-resolver-rules-sharing-cross-accounts.git?ref=1.0.0"
  source                    = "../../../../../../terraform-modules/terraform-module-route53-resolver-rules-sharing-cross-accounts"
  name                      = "${var.environment.resource_name_prefix}-route53-resolver-rule-on-premise-share"
  route53_resolver_rule_arn = aws_route53_resolver_rule.on-premise-to-outbound-endpoint[0].arn
  share_with_account_ids    = var.share_with_account_ids
  default_tags              = merge(var.default_tags, var.environment.default_tags)
}

output "client_vpn_dns_server_ips" {
  value = (var.route53_use_endpoints) ? aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address[*].ip : []
}
output "route53_endpoint_inbound_ips" {
  value = (var.route53_use_endpoints) ? aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address[*].ip : []
}
output "route53_endpoint_outbound_ips" {
  value = (var.route53_use_endpoints) ? aws_route53_resolver_endpoint.dns-endpoint-outbound[0].ip_address[*].ip : []
}