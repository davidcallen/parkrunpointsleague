# ---------------------------------------------------------------------------------------------------------------------
# Route53 : Hosted Zones for our sub-domain "core.parkrunpointsleague.org"
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_zone" "private" {
  count         = (module.global_variables.route53_enabled) ? 1 : 0
  name          = "${var.environment.name}.${module.global_variables.org_domain_name}"
  comment       = "Private zone for our VPC"
  force_destroy = true
  # Note: without specifying the vpc association here (below), we get a Public Zone (but wanted a Private one)
  # Hence could not use resource "aws_route53_zone_association"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  # Prevent the deletion of associated Backbone VPC, after the initial creation.
  # See documentation on aws_route53_zone_association for details :
  #    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association
  lifecycle {
    ignore_changes = [vpc]
  }
}
# Output our above Private Hosted Zone ID so this can be read by the backbone terraform when associating its VPC to cross-account Route53 Private Hosted Zones
# Note: this could also be achieved by reading terraform state files but then get caught in a catch-22 circular-dependancy hell.
resource "local_file" "route53_private_hosted_zone_id" {
  count                = (module.global_variables.route53_enabled) ? 1 : 0
  content              = aws_route53_zone.private[0].id
  directory_permission = "660"
  file_permission      = "660"
  filename             = "${path.module}/terraform-output-route53-private-hosted-zone-id"
}

# Get the Backbone VPC ID from an output file.
# Note: could get this from backbone's terraform state file, but would require change to how all this terraform invoked (via aws-vault).
# Also allowing the sharing of state files increases potential security blast-radius if a cross-account is compromised.
data "local_file" "backbone_vpc_id_file" {
  filename = "${path.module}/../backbone/terraform-output-vpc-id"
}

# Because the private hosted zone and DNS-VPC are in different accounts, we need to associate the private hosted zone with the backbone "DNS-VPC".
# To do that, you need to create authorization from the account that owns the private hosted zone and
# accept this authorization from the account that owns DNS-VPC
resource "aws_route53_vpc_association_authorization" "example" {
  count   = (module.global_variables.route53_enabled) ? 1 : 0
  vpc_id  = data.local_file.backbone_vpc_id_file.content
  zone_id = aws_route53_zone.private[0].id
}

data "aws_route53_resolver_rule" "aws-cloud" {
  count = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name  = "aws-cloud"
}
resource "aws_route53_resolver_rule_association" "aws-cloud" {
  count            = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name             = "${module.global_variables.org_short_name}-route53-dns-endpoint-inbound"
  resolver_rule_id = data.aws_route53_resolver_rule.aws-cloud[0].id
  vpc_id           = module.vpc.vpc_id
}
data "aws_route53_resolver_rule" "on-premise" {
  count = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name  = "on-premise"
}
resource "aws_route53_resolver_rule_association" "on-premise" {
  count            = (module.global_variables.route53_enabled && module.global_variables.route53_use_endpoints) ? 1 : 0
  name             = "${module.global_variables.org_short_name}-route53-dns-endpoint-outbound"
  resolver_rule_id = data.aws_route53_resolver_rule.on-premise[0].id
  vpc_id           = module.vpc.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Outputs for debugging etc...
# ---------------------------------------------------------------------------------------------------------------------
output "route53_private_hosted_zone_id" {
  value = aws_route53_zone.private[0].id
}
