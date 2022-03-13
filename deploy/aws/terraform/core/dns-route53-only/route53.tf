# ---------------------------------------------------------------------------------------------------------------------
# Route53 : Hosted Zones for our sub-domain "core.parkrunpointsleague.org"
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_zone" "public" {
  name          = "${var.environment.name}.${var.org_domain_name}"
  comment       = "Public HostedZone for ${var.environment.name}.${var.org_domain_name}"
  force_destroy = false
}
# Output our above Public Hosted Zone ID so this can be read by the terraform in other accounts
# so the TLD PublicHZ can delegate to this subdomain PublicHZ by adding an NS (dns) record pointing to our NS server IPs.
# Note: this could also be achieved by reading terraform state files but then get caught in a catch-22 circular-dependancy hell.
resource "local_file" "route53_public_hosted_zone_name_servers" {
  content              = join(",", aws_route53_zone.public.name_servers)
  directory_permission = "660"
  file_permission      = "660"
  filename             = "${path.module}/../outputs/terraform-output-route53-public-hosted-zone-name-servers"
}

resource "aws_route53_zone" "private" {
  name          = "${var.environment.name}.${var.org_domain_name}"
  comment       = "Private zone for our VPC"
  force_destroy = true
  # Note: without specifying the vpc association here (below), we get a Public Zone (but wanted a Private one)
  # Hence could not use resource "aws_route53_zone_association"
  vpc {
    vpc_id = var.vpc.vpc_id
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
  content              = aws_route53_zone.private.id
  directory_permission = "660"
  file_permission      = "660"
  filename             = "${path.module}/../outputs/terraform-output-route53-private-hosted-zone-id"
}

# Get the Backbone VPC ID from an output file.
# Note: could get this from backbone's terraform state file, but would require change to how all this terraform invoked (via aws-vault).
# Also allowing the sharing of state files increases potential security blast-radius if a cross-account is compromised.
data "local_file" "backbone_vpc_id_file" {
  filename = "${path.module}/../../backbone/outputs/terraform-output-backbone-vpc-id"
}

# Because the private hosted zone and DNS-VPC are in different accounts, we need to associate the private hosted zone with the backbone "DNS-VPC".
# To do that, you need to create authorization from the account that owns the private hosted zone and
# accept this authorization from the account that owns DNS-VPC
resource "aws_route53_vpc_association_authorization" "example" {
  vpc_id  = data.local_file.backbone_vpc_id_file.content
  zone_id = aws_route53_zone.private.id
}

