output "route53_private_hosted_zone_id" {
  value = data.local_file.backbone_phz_id_file.content
}
