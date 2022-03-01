# ---------------------------------------------------------------------------------------------------------------------
# Route53 : Hosted Zones for our sub-domain "core.parkrunpointsleague.org"
# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_route53_zone" "private" {
//  name          = "${var.environment.name}.${var.org_domain_name}"
//  comment       = "Private zone for our VPC"
//  force_destroy = true
//  # Note: without specifying the vpc association here (below), we get a Public Zone (but wanted a Private one)
//  # Hence could not use resource "aws_route53_zone_association"
//  vpc {
//    vpc_id = var.vpc.vpc_id
//  }
//  # Prevent the deletion of associated Backbone VPC, after the initial creation.
//  # See documentation on aws_route53_zone_association for details :
//  #    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association
//  lifecycle {
//    ignore_changes = [vpc]
//  }
//}

//
//# DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG - #SIMPLE_AD testing move this to backbone?
//resource "aws_route53_zone" "private-tld" {
//  name          = var.org_domain_name
//  comment       = "Private zone for our VPC"
//  force_destroy = true
//  # Note: without specifying the vpc association here (below), we get a Public Zone (but wanted a Private one)
//  # Hence could not use resource "aws_route53_zone_association"
//  vpc {
//    vpc_id = var.vpc.vpc_id
//  }
//  # Prevent the deletion of associated Backbone VPC, after the initial creation.
//  # See documentation on aws_route53_zone_association for details :
//  #    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association
//  lifecycle {
//    ignore_changes = [vpc]
//  }
//}
//# DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG - #SIMPLE_AD testing move this to backbone?

# Output our VPC ID so this can be read by the backbone terraform when associating to backbone account Route53 Private Hosted Zone.
# Note: this could also be achieved by reading terraform state files but then get caught in a catch-22 circular-dependancy hell.
resource "local_file" "vpc_id" {
  content              = var.vpc.vpc_id
  directory_permission = "660"
  file_permission      = "660"
  filename             = "${path.module}/../outputs/terraform-output-vpc-id"
}

# Get the Backbone PHZ ID from an output file.
# Note: could get this from backbone's terraform state file, but would require change to how all this terraform invoked (via aws-vault).
# Also allowing the sharing of state files increases potential security blast-radius if a cross-account is compromised.
data "local_file" "backbone_phz_id_file" {
  filename = "${path.module}/../../backbone/outputs/terraform-output-route53-phz-id"
}

//resource "aws_route53_zone_association" "backbone-phz-and-our-vpc" {
//  zone_id = data.local_file.backbone_phz_id_file.content
//  vpc_id  = var.vpc.vpc_id
//}

# Because the private hosted zone and DNS-VPC are in different accounts, we need to associate the private hosted zone with the backbone "DNS-VPC".
# To do that, you need to create authorization from the account that owns the private hosted zone and
# accept this authorization from the account that owns DNS-VPC
//resource "aws_route53_vpc_association_authorization" "backbone-phz-and-our-vpc" {
//  vpc_id  = var.vpc.vpc_id
//  zone_id = data.local_file.backbone_phz_id_file.content
//}
resource "aws_route53_zone_association" "backbone-phz-and-our-vpc" {
  vpc_id  = var.vpc.vpc_id
  zone_id = data.local_file.backbone_phz_id_file.content
}

