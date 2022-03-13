resource "aws_route53_zone_association" "backbone-private-and-other-vpcs" {
  count   = length(var.other_account_private_hosted_zone_ids)
  zone_id = var.other_account_private_hosted_zone_ids[count.index]
  vpc_id  = var.backbone_vpc_id
}

# Create NS records in our Public Hosted Zone for each of our accounts subdomains, to delegate the DNS to them.
resource "aws_route53_record" "delegate-to-public-subdomains-in-other-accounts" {
  count           = length(var.other_account_public_hosted_zone_name_servers)
  allow_overwrite = true
  name            = var.other_account_public_hosted_zone_names[count.index]
  records         = toset(split(",", var.other_account_public_hosted_zone_name_servers[count.index]))
  ttl             = 60
  type            = "NS"
  zone_id         = var.backbone_public_hosted_zone_id
}