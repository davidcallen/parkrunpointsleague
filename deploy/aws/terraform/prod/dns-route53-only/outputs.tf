# ---------------------------------------------------------------------------------------------------------------------
# Outputs for debugging etc...
# ---------------------------------------------------------------------------------------------------------------------
output "route53_public_subdomain_hosted_zone_id" {
  value = aws_route53_zone.public.id
}
output "route53_private_hosted_zone_id" {
  value = aws_route53_zone.private.id
}
output "ec2_test_ip_address" {
  value = (var.route53_testing_mode_enabled) ? aws_instance.test[0].private_ip : ""
}
