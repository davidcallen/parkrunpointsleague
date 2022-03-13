# Moved the below out of DNS module so not destroyed and recreated as often.
# Because domain registry need Name Servers updated every time, and also takes some time for it to propogate out there.
# Only costs $0.50 per month so ok
# Put it back in DNS module before 8 April 2022
resource "aws_route53_zone" "public" {
  name          = module.global_variables.org_domain_name
  comment       = "HostedZone created by Route53 Registrar"
  force_destroy = false
}