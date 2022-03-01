data "aws_route53_resolver_rule" "aws-cloud-outbound-endpoint-to-internal-dns" {
  count = (var.route53_use_endpoints) ? 1 : 0
  name  = "aws-cloud-outbound-endpoint-to-internal-dns"
}
resource "aws_route53_resolver_rule_association" "aws-cloud-outbound-endpoint-to-internal-dns" {
  count            = (var.route53_use_endpoints) ? 1 : 0
  name             = "${var.org_short_name}-aws-cloud-outbound-endpoint-to-internal-dns"
  resolver_rule_id = data.aws_route53_resolver_rule.aws-cloud-outbound-endpoint-to-internal-dns[0].id
  vpc_id           = var.vpc.vpc_id
}
data "aws_route53_resolver_rule" "on-premise-to-outbound-endpoint" {
  count = (var.route53_use_endpoints) ? 1 : 0
  name  = "on-premise-to-outbound-endpoint"
}
resource "aws_route53_resolver_rule_association" "on-premise-to-outbound-endpoint" {
  count            = (var.route53_use_endpoints) ? 1 : 0
  name             = "${var.org_short_name}-on-premise-to-outbound-endpoint"
  resolver_rule_id = data.aws_route53_resolver_rule.on-premise-to-outbound-endpoint[0].id
  vpc_id           = var.vpc.vpc_id
}