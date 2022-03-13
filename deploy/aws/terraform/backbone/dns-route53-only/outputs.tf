output "route53_public_tld_hosted_zone_id" {
  value = data.aws_route53_zone.public.id
}
output "route53_public_subdomain_hosted_zone_id" {
  value = aws_route53_zone.public-backbone.id
}
output "route53_private_hosted_zone_id" {
  value = aws_route53_zone.private.id
}
output "client_vpn_dns_server_ips" {
  # value = (var.route53_use_endpoints) ? tolist([for ip_address in aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address[*] : ip_address["ip"]]) : []
  value = (var.route53_use_endpoints) ? aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address[*].ip : []
  # value = aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address
}
output "route53_endpoint_inbound_ips" {
  value = (var.route53_use_endpoints) ? aws_route53_resolver_endpoint.dns-endpoint-inbound[0].ip_address[*].ip : []
}
output "route53_endpoint_outbound_ips" {
  value = (var.route53_use_endpoints) ? aws_route53_resolver_endpoint.dns-endpoint-outbound[0].ip_address[*].ip : []
}
