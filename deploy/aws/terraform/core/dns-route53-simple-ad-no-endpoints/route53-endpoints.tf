data "aws_route53_resolver_rule" "aws-cloud" {
  count = (var.route53_use_endpoints) ? 1 : 0
  name  = "aws-cloud"
}
resource "aws_route53_resolver_rule_association" "aws-cloud" {
  count            = (var.route53_use_endpoints) ? 1 : 0
  name             = "${var.org_short_name}-route53-dns-endpoint-inbound"
  resolver_rule_id = data.aws_route53_resolver_rule.aws-cloud[0].id
  vpc_id           = var.vpc.vpc_id
}
data "aws_route53_resolver_rule" "on-premise" {
  count = (var.route53_use_endpoints) ? 1 : 0
  name  = "on-premise"
}
resource "aws_route53_resolver_rule_association" "on-premise" {
  count            = (var.route53_use_endpoints) ? 1 : 0
  name             = "${var.org_short_name}-route53-dns-endpoint-outbound"
  resolver_rule_id = data.aws_route53_resolver_rule.on-premise[0].id
  vpc_id           = var.vpc.vpc_id
}