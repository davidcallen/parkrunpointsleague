# Uncomment below for convenient testing of EC2/ECS with ALB in Backbone - cheaper than using Core for quick tests.
//# ---------------------------------------------------------------------------------------------------------------------
//# Public Application Load Balancer
//# ---------------------------------------------------------------------------------------------------------------------
//module "lb-public" {
//  # source                      = "git@github.com:davidcallen/terraform-module-aws-load-balancer-application.git?ref=1.0.0"
//  source                           = "../../../../../terraform-modules/terraform-module-aws-load-balancer-application"
//  name                             = substr("${var.environment.resource_name_prefix}-alb-public", 0, 32)
//  internal                         = false # internet-facing
//  enable_cross_zone_load_balancing = true
//  vpc_id                           = module.vpc.vpc_id
//  subnet_ids                       = module.vpc.public_subnets
//  ip_address_type                  = "ipv4"
//  security_group_ids               = [] # By passing no security_group_ids it will create its own default one
//  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
//    Name       = "${var.environment.resource_name_prefix}-alb-public"
//    Visibility = "public"
//  })
//  enable_deletion_protection = var.environment.resource_deletion_protection
//}
//
//# ---------------------------------------------------------------------------------------------------------------------
//# Load Balancer HTTPS listener
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_lb_listener" "alb-public-https" {
//  load_balancer_arn = module.lb-public.load-balancer.arn
//  port              = 443
//  protocol          = "HTTPS"
//  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
//  certificate_arn   = aws_acm_certificate.alb-public-default-listener.arn
//  default_action {
//    type = "fixed-response"
//    fixed_response {
//      content_type = "text/plain"
//      message_body = "404 Not Found"
//      status_code  = "404"
//    }
//  }
//}
//# ---------------------------------------------------------------------------------------------------------------------
//# Load Balancer HTTP listener - for enabling redirect response to https
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_lb_listener" "alb-public-http" {
//  load_balancer_arn = module.lb-public.load-balancer.arn
//  port              = 80
//  protocol          = "HTTP"
//  default_action {
//    type = "redirect"
//    redirect {
//      port        = "443"
//      protocol    = "HTTPS"
//      status_code = "HTTP_301"
//    }
//  }
//}
//# ---------------------------------------------------------------------------------------------------------------------
//# SSL certificate for use on App Load Balancer HTTPS **default** listener
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_acm_certificate" "alb-public-default-listener" {
//  domain_name       = "*.${var.environment.name}.${module.global_variables.org_domain_name}"
//  validation_method = "DNS"
//  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
//    Name = "${var.environment.resource_name_prefix}-alb-public-default-listener-cert"
//  })
//  lifecycle {
//    create_before_destroy = true
//  }
//}
//resource "aws_route53_record" "alb-public-default-listener" {
//  for_each = {
//    for dvo in aws_acm_certificate.alb-public-default-listener.domain_validation_options : dvo.domain_name => {
//      name   = dvo.resource_record_name
//      record = dvo.resource_record_value
//      type   = dvo.resource_record_type
//    }
//  }
//  allow_overwrite = true
//  name            = each.value.name
//  records         = [each.value.record]
//  ttl             = 60
//  type            = each.value.type
//  zone_id         = module.dns[0].route53_public_subdomain_hosted_zone_id
//  # zone_id         = module.dns[0].route53_private_hosted_zone_id
//  # zone_id = data.local_file.route53_backbone_public_hosted_zone_id_files.content
//}
//resource "aws_acm_certificate_validation" "alb-public-default-listener" {
//  certificate_arn         = aws_acm_certificate.alb-public-default-listener.arn
//  validation_record_fqdns = [for record in aws_route53_record.alb-public-default-listener : record.fqdn]
//}
//
//
//# ---------------------------------------------------------------------------------------------------------------------
//# Security Groups - default rules
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_security_group_rule" "alb-public-allow-ingress-http" {
//  type              = "ingress"
//  description       = "http for enabling redirect response to https"
//  from_port         = 80
//  to_port           = 80
//  protocol          = "tcp"
//  cidr_blocks       = ["0.0.0.0/0"]
//  security_group_id = module.lb-public.security_group_id
//}
//resource "aws_security_group_rule" "alb-public-allow-ingress-https" {
//  type              = "ingress"
//  description       = "https"
//  from_port         = 443
//  to_port           = 443
//  protocol          = "tcp"
//  cidr_blocks       = ["0.0.0.0/0"]
//  security_group_id = module.lb-public.security_group_id
//}
//# --------------------------------------- egress ------------------------------------------------------------------
//resource "aws_security_group_rule" "alb-public-allow-egress-http" {
//  type              = "egress"
//  description       = "http"
//  from_port         = 80
//  to_port           = 80
//  protocol          = "tcp"
//  cidr_blocks       = ["0.0.0.0/0"]
//  security_group_id = module.lb-public.security_group_id
//}
//resource "aws_security_group_rule" "alb-public-allow-egress-https" {
//  type              = "egress"
//  description       = "https"
//  from_port         = 443
//  to_port           = 443
//  protocol          = "tcp"
//  cidr_blocks       = ["0.0.0.0/0"]
//  security_group_id = module.lb-public.security_group_id
//}
