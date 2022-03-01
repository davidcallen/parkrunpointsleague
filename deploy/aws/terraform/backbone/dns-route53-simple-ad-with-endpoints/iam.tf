
//# ---------------------------------------------------------------------------------------------------------------------
//# IAM
//# ---------------------------------------------------------------------------------------------------------------------
//module "iam-simple-ad-admin" {
//  # source           = "git@github.com:davidcallen/terraform-module-iam-simple-ad-admin.git?ref=1.0.0"
//  source                  = "../../../../../../terraform-modules/terraform-module-iam-simple-ad-admin"
//  resource_name_prefix    = var.environment.resource_name_prefix
//  route53_private_zone_id = aws_route53_zone.private.id
//  secrets_arns = [
//    module.simple-ad-admin-password-secret.secret_arn,
//  ]
//  tags = merge(var.default_tags, var.environment.default_tags, {
//    Name        = "${var.environment.resource_name_prefix}-simple-ad-admin"
//    Application = "simple-ad"
//  })
//}