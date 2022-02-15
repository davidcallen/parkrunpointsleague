resource "aws_route53_zone_association" "backbone-private-and-other-vpcs" {
  count   = length(var.other_account_private_hosted_zone_ids)
  zone_id = var.other_account_private_hosted_zone_ids[count.index]
  vpc_id  = var.backbone_vpc_id
}