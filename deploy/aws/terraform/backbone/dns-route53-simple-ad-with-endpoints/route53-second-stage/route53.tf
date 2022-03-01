//resource "aws_route53_zone_association" "backbone-private-and-other-vpcs" {
//  count   = length(var.other_account_private_hosted_zone_ids)
//  zone_id = var.other_account_private_hosted_zone_ids[count.index]
//  vpc_id  = var.backbone_vpc_id
//}

# Create authorization from the account that owns the private hosted zone and
# accept this authorization from the other account that contain the VPCs
resource "aws_route53_vpc_association_authorization" "backbone-phz-to-cross-account-vpcs" {
  count   = length(var.cross_account_vpc_ids)
  vpc_id  = var.cross_account_vpc_ids[count.index]
  zone_id = var.backbone_private_zone_id
}
//resource "aws_route53_zone_association" "backbone-private-and-other-vpcs" {
//  count   = length(var.cross_account_vpc_ids)
//  vpc_id  = var.cross_account_vpc_ids[count.index]
//  zone_id = var.backbone_private_zone_id
//}
