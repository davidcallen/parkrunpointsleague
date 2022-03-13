# ---------------------------------------------------------------------------------------------------------------------
# Route53 : Hosted Zones for our domain "parkrunpointsleague.org"
# ---------------------------------------------------------------------------------------------------------------------
# Imported the automatically created Zone (upon domain registration) using terraform :
#    terraform-v1.0.11 import aws_route53_zone.public Z05031252J93KZFK3MNHW

// Moved out of this module so not destroyed and recreated as often - cause domain registery need Name Servers updated every time. Only costs $0.50 per month
//resource "aws_route53_zone" "public" {
//  name          = var.org_domain_name
//  comment       = "HostedZone created by Route53 Registrar"
//  force_destroy = false
//}
data "aws_route53_zone" "public" {
  name = var.org_domain_name
}

// This new feature not currently working :(    Get error :
//  error reading Route 53 Domains Domain (parkrunpointsleague.org): operation error Route 53 Domains: GetDomainDetail, exceeded maximum number of attempts, 9, https response error StatusCode: 0, RequestID: , request send failed, Post "https://route53domains.eu-west-1.amazonaws.com/": dial tcp: lookup route53domains.eu-west-1.amazonaws.com on 127.0.0.53:53: no such host
//
// ...for now will have to manually change the name_servers on the registered domain !
//
//resource "aws_route53domains_registered_domain" "public" {
//  domain_name = var.org_domain_name
//  dynamic "name_server" {
//    for_each = aws_route53_zone.public.name_servers
//    content {
//      name = name_server.value
//    }
//  }
//  tags = var.default_tags
//}

# Create NS records in our TLD Public Hosted Zone for this accounts subdomain, to delegate the DNS to its subdomain PublicHZ.
resource "aws_route53_record" "delegate-to-public-subdomain-in-this-account" {
  allow_overwrite = true
  name            = "${var.environment.name}.${var.org_domain_name}"
  records         = aws_route53_zone.public-backbone.name_servers
  ttl             = 60
  type            = "NS"
  zone_id         = data.aws_route53_zone.public.id
}
# ---------------------------------------------------------------------------------------------------------------------
# Route53 : Hosted Zones for our environments subdomain "backbone.parkrunpointsleague.org"
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_zone" "public-backbone" {
  name          = "${var.environment.name}.${var.org_domain_name}"
  comment       = "HostedZone created by Route53 Registrar"
  force_destroy = true
}

//# Output our above Public Hosted Zone ID so this can be read by the terraform in other accounts
//# Note: this could also be achieved by reading terraform state files but then get caught in a catch-22 circular-dependancy hell.
//resource "local_file" "route53_public_hosted_zone_id" {
//  content              = aws_route53_zone.public.name_servers
//  directory_permission = "660"
//  file_permission      = "660"
//  filename             = "${path.module}/../outputs/terraform-output-route53-public-hosted-zone"
//}

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
  other_account_public_hosted_zone_name_servers_filenames = fileset("${path.module}/../..", "*/outputs/terraform-output-route53-public-hosted-zone-name-servers")
  other_account_private_hosted_zone_ids_filenames         = fileset("${path.module}/../..", "*/outputs/terraform-output-route53-private-hosted-zone-id")
}
data "local_file" "route53_public_hosted_zone_files" {
  for_each = local.other_account_public_hosted_zone_name_servers_filenames
  filename = "${path.module}/../../${each.value}"
}
data "local_file" "route53_private_hosted_zone_id_files" {
  for_each = local.other_account_private_hosted_zone_ids_filenames
  filename = "${path.module}/../../${each.value}"
}
module "route53-second-stage" {
  source                                        = "./route53-second-stage"
  backbone_vpc_id                               = var.vpc.vpc_id
  backbone_public_hosted_zone_id                = data.aws_route53_zone.public.id
  other_account_public_hosted_zone_name_servers = [for file in data.local_file.route53_public_hosted_zone_files : file["content"]]
  other_account_public_hosted_zone_names        = [for file_name_path in local.other_account_public_hosted_zone_name_servers_filenames : "${dirname(dirname(file_name_path))}.${var.org_domain_name}"]
  other_account_private_hosted_zone_ids         = [for file in data.local_file.route53_private_hosted_zone_id_files : file["content"]]
}


