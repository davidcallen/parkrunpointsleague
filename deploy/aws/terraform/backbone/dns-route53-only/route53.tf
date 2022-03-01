# ---------------------------------------------------------------------------------------------------------------------
# Route53 : Hosted Zones for our domain "parkrunpointsleague.org"
# ---------------------------------------------------------------------------------------------------------------------
# Imported the automatically created Zone (upon domain registration) using terraform :
#    terraform-v1.0.11 import aws_route53_zone.public Z05031252J93KZFK3MNHW
resource "aws_route53_zone" "public" {
  name          = var.org_domain_name
  comment       = "HostedZone created by Route53 Registrar"
  force_destroy = false
}
# Note: The NS and SOA are automatically created when the Hosted Zone is created.
#
//# Imported the automatically created NS entry (upon domain registration) using terraform :
//#    terraform import aws_route53_record.ns Z05031252J93KZFK3MNHW_parkrunpointsleague.org_NS
//# Note the record ID is in the form ZONEID_RECORDNAME_TYPE_SET-IDENTIFIER (e.g. Z4KAPRWWNC7JR_dev.example.com_NS_dev), where SET-IDENTIFIER is optional
//resource "aws_route53_record" "ns" {
//  zone_id = aws_route53_zone.public.zone_id
//  name    = var.org_domain_name
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
//  zone_id = aws_route53_zone.public.zone_id
//  name    = var.org_domain_name
//  type    = "SOA"
//  ttl     = 900
//  records = [
//    "${trim(aws_route53_zone.public.name_servers[0], ".")}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
//  ]
//}

resource "aws_route53_zone" "private" {
  name          = "${var.environment.name}.${var.org_domain_name}"
  comment       = "Private zone for our VPC"
  force_destroy = true
  # Note: without specifying the vpc association here (below), we get a Public Zone (but wanted a Private one)
  # Hence could not use the resource "aws_route53_zone_association" for this association
  vpc {
    vpc_id = var.vpc.vpc_id
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECOND STAGE : This needs to be run after a creation/change of one (or more) cross-account Private Hosted Zones (in other accounts)
# This Stage will attempt to associate the Backbone VPC with those cross-account Private Hosted Zones.
# Otherwise no DNS resolution from Backbone to cross-account hosted FQDNs
# ---------------------------------------------------------------------------------------------------------------------
locals {
  route53_private_hosted_zone_id_filenames = fileset("${path.module}/../..", "*/outputs/terraform-output-route53-private-hosted-zone-id")
}
data "local_file" "route53_private_hosted_zone_id_files" {
  for_each = local.route53_private_hosted_zone_id_filenames
  filename = "${path.module}/../../${each.value}"
}
module "route53-second-stage" {
  source                                = "./route53-second-stage"
  backbone_vpc_id                       = var.vpc.vpc_id
  other_account_private_hosted_zone_ids = [for file in data.local_file.route53_private_hosted_zone_id_files : file["content"]]
}
//output "route53_inbound_endpoint_ips" {
//  value = aws_route53_resolver_endpoint.dns-endpoint-inbound.ip_address[*].ip
//}

