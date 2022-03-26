
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
# Route53 Forwarding Rules
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
# Outbound Endpoint Forward "parkrunpointsleague.org" requests back to the Inbound Endpoint
resource "aws_route53_resolver_rule" "aws-cloud" {
  count                = (var.route53_use_endpoints) ? 1 : 0
  domain_name          = var.org_domain_name
  name                 = "aws-cloud"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-outbound[0].id
  dynamic "target_ip" {
    for_each = aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
    #     for_each = (module.global_variables.central_directory_enabled) ? toset([{ip = "10.6.1.209"}, {ip = "10.6.2.43"}]) : aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
    content {
      ip = target_ip.value.ip
    }
  }
  tags = merge(var.default_tags, var.environment.default_tags)
}

# Outbound Endpoint Forward "amazonaws.com" requests back to the Inbound Endpoint
#  ...this needed for EKS API Endpoint DNS resolution (and other services like ALB DNS endpoint)
resource "aws_route53_resolver_rule" "aws-services" {
  count                = (var.route53_use_endpoints) ? 1 : 0
  domain_name          = "amazonaws.com"
  name                 = "aws-services"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.dns-endpoint-outbound[0].id
  dynamic "target_ip" {
    for_each = aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
    #     for_each = (module.global_variables.central_directory_enabled) ? toset([{ip = "10.6.1.209"}, {ip = "10.6.2.43"}]) : aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
    content {
      ip = target_ip.value.ip
    }
  }
  tags = merge(var.default_tags, var.environment.default_tags)
}

//resource "aws_route53_resolver_rule_association" "aws-cloud" {
//  name             = "${var.org_short_name}-route53-dns-endpoint-inbound"
//  resolver_rule_id = aws_route53_resolver_rule.aws-cloud[0].id
//  vpc_id           = var.vpc.vpc_id
//}
# Outbound EndPoint Forward the on-premise domain names requests to our on-premise DNS server
resource "aws_route53_resolver_rule" "on-premise" {
  count                = (var.route53_use_endpoints) ? 1 : 0
  domain_name          = var.on_premise_domain_name
  name                 = "on-premise"
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
resource "aws_route53_resolver_rule_association" "on-premise" {
  count            = (var.route53_use_endpoints) ? 1 : 0
  name             = "${var.org_short_name}-route53-dns-endpoint-outbound"
  resolver_rule_id = aws_route53_resolver_rule.on-premise[0].id
  vpc_id           = var.vpc.vpc_id
}
# Share above Route53 resolver rules into our other accounts
module "route53-resolver-rule-inbound-sharing-cross-accounts" {
  count = (var.route53_use_endpoints) ? 1 : 0
  # source                  = "git@github.com:davidcallen/terraform-module-route53-resolver-rules-sharing-cross-accounts.git?ref=1.0.0"
  source                    = "../../../../../../terraform-modules/terraform-module-route53-resolver-rules-sharing-cross-accounts"
  name                      = "${var.environment.resource_name_prefix}-route53-resolver-rule-aws-cloud-share"
  route53_resolver_rule_arn = aws_route53_resolver_rule.aws-cloud[0].arn
  share_with_account_ids    = var.share_with_account_ids
  default_tags              = merge(var.default_tags, var.environment.default_tags)
}
module "route53-resolver-rule-outbound-sharing-cross-accounts" {
  count = (var.route53_use_endpoints) ? 1 : 0
  # source                  = "git@github.com:davidcallen/terraform-module-route53-resolver-rules-sharing-cross-accounts.git?ref=1.0.0"
  source                    = "../../../../../../terraform-modules/terraform-module-route53-resolver-rules-sharing-cross-accounts"
  name                      = "${var.environment.resource_name_prefix}-route53-resolver-rule-on-premise-share"
  route53_resolver_rule_arn = aws_route53_resolver_rule.on-premise[0].arn
  share_with_account_ids    = var.share_with_account_ids
  default_tags              = merge(var.default_tags, var.environment.default_tags)
}
