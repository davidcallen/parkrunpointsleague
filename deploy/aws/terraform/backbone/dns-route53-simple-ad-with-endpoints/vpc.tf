//# Instead of point to SimpleAD DNS, use a Route53 Forwarder to it. This should fix the EFS DNS resolution issue.
//resource "aws_vpc_dhcp_options" "simple-directory" {
//  domain_name         = var.org_domain_name
//  domain_name_servers = aws_directory_service_directory.simple-directory.dns_ip_addresses
//  tags                = merge(var.default_tags, var.environment.default_tags)
//}
//resource "aws_vpc_dhcp_options_association" "simple-directory" {
//  vpc_id          = var.vpc.vpc_id
//  dhcp_options_id = aws_vpc_dhcp_options.simple-directory.id
//}