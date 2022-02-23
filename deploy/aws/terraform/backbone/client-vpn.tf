# ---------------------------------------------------------------------------------------------------------------------
# Client VPN.
#  Useful if do not have an on-premise network-attached VPN Device.
#  First create the necessary certs and keys for the VPN (e.g. ~/.cert/nm-openvpn/prpl-client-vpn-server.key) using scripts/create-client-vpn-cert.sh
#  Then distribute the client cert and key to Users.
#  Download the VPN config file (".openvpn") to create connection from PC/Laptops. And ensure using config of :
#     CA Certificate     = downloaded-client-config-ca.pem
#     User Certificate   = prpl-client-vpn-client.crt
#     User Private Key   = prpl-client-vpn-client.key
# ---------------------------------------------------------------------------------------------------------------------
//
//resource "tls_private_key" "client-vpn-key" {
//  count     = (var.client_vpn.enabled) ? 1 : 0
//  algorithm = "RSA"
//
//}
//
//resource "tls_self_signed_cert" "client-vpn-cert" {
//  count           = (var.client_vpn.enabled) ? 1 : 0
//  key_algorithm   = "RSA"
//  private_key_pem = "/home/david.allen/.cert/nm-openvpn/${var.environment.resource_name_prefix}-client-vpn.pem" # "${tls_private_key.example.private_key_pem}"
//  subject {
//    common_name  = module.global_variables.org_domain_name
//    organization = module.global_variables.org_name
//  }
//  validity_period_hours = 19728
//  allowed_uses = [
//    "key_encipherment",
//    "digital_signature",
//    "server_auth",
//  ]
//}
//resource "aws_acm_certificate" "client-vpn" {
//  domain_name       = module.global_variables.org_domain_name
//  validation_method = "DNS"
//  tags = {
//    Environment = "test"
//  }
//  lifecycle {
//    create_before_destroy = true
//  }
//}

resource "aws_acm_certificate" "client-vpn-server-cert" {
  count = (var.client_vpn.enabled) ? 1 : 0
  # private_key      = tls_private_key.client-vpn-key[0].private_key_pem
  private_key = file("~/.cert/nm-openvpn/prpl-client-vpn-server.key")
  # certificate_body = tls_self_signed_cert.client-vpn-cert[0].cert_pem
  certificate_body  = file("~/.cert/nm-openvpn/prpl-client-vpn-server.crt")
  certificate_chain = file("~/.cert/nm-openvpn/prpl-client-vpn-ca.crt")
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name = "${var.environment.resource_name_prefix}-client-vpn-server-cert"
  })
}
// For use with Mutual Authentication
//resource "aws_acm_certificate" "client-vpn-client-cert" {
//  count             = (var.client_vpn.enabled) ? 1 : 0
//  private_key       = file("~/.cert/nm-openvpn/prpl-client-vpn-client.key")
//  certificate_body  = file("~/.cert/nm-openvpn/prpl-client-vpn-client.crt")
//  certificate_chain = file("~/.cert/nm-openvpn/prpl-client-vpn-ca.crt")
//}

# ---------------------------------------------------------------------------------------------------------------------
# SECOND STAGE : This needs to be run after a creation/change of the Central Directory (AD) in Core
# This Stage will attempt to associate the ClientVPN with DNS IPs for that Central Directory
# ---------------------------------------------------------------------------------------------------------------------
locals {
  central_directory_dns_ips_filenames = fileset("${path.module}/..", "*/outputs/terraform-output-central-directory-dns-ips")
}
data "local_file" "central_directory_dns_ips" {
  for_each = local.central_directory_dns_ips_filenames
  filename = "${path.module}/../${each.value}"
}
locals {
  central_directory_dns_ips_str = (module.global_variables.central_directory_enabled && length(data.local_file.central_directory_dns_ips) > 0) ? data.local_file.central_directory_dns_ips["core/outputs/terraform-output-central-directory-dns-ips"].content : ""
  central_directory_dns_ips     = (length(local.central_directory_dns_ips_str) > 0) ? split(",", local.central_directory_dns_ips_str) : []
}
output "central_directory_dns_ips" {
  value = data.local_file.central_directory_dns_ips
}
resource "aws_ec2_client_vpn_endpoint" "client-vpn" {
  count                  = (var.client_vpn.enabled) ? 1 : 0
  description            = "${var.environment.resource_name_prefix}-client-vpn"
  server_certificate_arn = aws_acm_certificate.client-vpn-server-cert[0].arn
  client_cidr_block      = var.client_vpn.client_cidr_block

  dns_servers            = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? module.dns[0].client_vpn_dns_server_ips : (length(local.central_directory_dns_ips) > 0) ? local.central_directory_dns_ips : (module.global_variables.route53_enabled) ? [cidrhost(module.vpc.vpc_cidr_block, 2)] : ["8.8.8.8", "8.8.4.4"] #COST-SAVING
  # dns_servers            = local.central_directory_dns_ips  # TEMP HACK

  split_tunnel = true
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client-vpn-server-cert[0].arn
  }
  connection_log_options {
    enabled               = var.client_vpn.cloudwatch_logging_enabled
    cloudwatch_log_group  = aws_cloudwatch_log_group.client-vpn[0].name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client-vpn[0].name
  }
  tags = merge(module.global_variables.default_tags, {
    Name = "${var.environment.resource_name_prefix}-client-vpn"
  })
}
output "client_vpn_dns_server_ips" {
  value = (var.client_vpn.enabled) ? aws_ec2_client_vpn_endpoint.client-vpn[0].dns_servers : []
}

# Note this VPN -> VPC association can take up to 12 mins to completion
resource "aws_ec2_client_vpn_network_association" "client-vpn" {
  count                  = (var.client_vpn.enabled) ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client-vpn[0].id
  subnet_id              = module.vpc.private_subnets[0]
}

# Authorize access to our CIDRs from Client VPN (all connected clients)
resource "aws_ec2_client_vpn_authorization_rule" "client-vpn-to-vpcs" {
  count                  = (var.client_vpn.enabled) ? length(var.client_vpn.authorize_account_cidrs) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client-vpn[0].id
  target_network_cidr    = var.client_vpn.authorize_account_cidrs[count.index]
  authorize_all_groups   = true
}

# Routing to be advertised by the Client VPN to the connected Laptop/PC
resource "aws_ec2_client_vpn_route" "client-vpn-to-vpcs" {
  count                  = (var.client_vpn.enabled) ? length(var.client_vpn.routing_to_account_cidrs) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client-vpn[0].id
  destination_cidr_block = var.client_vpn.routing_to_account_cidrs[count.index]
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.client-vpn[0].subnet_id
}
# ---------------------------------------------------------------------------------------------------------------------
# Client VPN : Cloudwatch
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "client-vpn" {
  count             = (var.client_vpn.enabled && var.client_vpn.cloudwatch_logging_enabled) ? 1 : 0
  name              = "client-vpn"
  retention_in_days = var.client_vpn.cloudwatch_log_groups_retention_days
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "client-vpn"
    Application = "AWS Client VPN"
  })
}
resource "aws_cloudwatch_log_stream" "client-vpn" {
  count = (var.client_vpn.enabled && var.client_vpn.cloudwatch_logging_enabled) ? 1 : 0
  #name              = "client-vpn-${aws_ec2_client_vpn_endpoint.client-vpn[0].arn}"
  name           = "client-vpn"
  log_group_name = aws_cloudwatch_log_group.client-vpn[0].name
}
# Use this DNS Name in your PC's openvpn client config for connecting to AWS
output "client_vpn_dns_name" {
  value = aws_ec2_client_vpn_endpoint.client-vpn[0].dns_name
}