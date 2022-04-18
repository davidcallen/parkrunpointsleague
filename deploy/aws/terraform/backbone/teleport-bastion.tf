# ---------------------------------------------------------------------------------------------------------------------
# Deploy a Teleport server (all-in-one, non-HA) and a test ec2 instance to join the teleport cluster
# ---------------------------------------------------------------------------------------------------------------------
module "teleport-bastion" {
  source = "../../../../../terraform-modules/terraform-module-aws-teleport"
  # source                    = "git@github.com:davidcallen/terraform-module-aws-teleport.git?ref=1.0.0"
  region      = module.global_variables.aws_region
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  //  vpc_public_subnet_ids         = module.vpc.public_subnets
  //  vpc_public_subnet_cidrs       = module.vpc.public_subnets_cidr_blocks
  vpc_private_subnet_ids   = module.vpc.private_subnets
  vpc_private_subnet_cidrs = module.vpc.private_subnets_cidr_blocks
  route53_hosted_zone_id   = module.dns[0].route53_private_hosted_zone_id
  # Cluster name is a unique cluster name to use, should be unique and not contain spaces or other special characters
  cluster_name = "teleport"
  # AWS SSH key pair name to provision in installed instances, must be a key pair available in the above defined region (AWS Console > EC2 > Key Pairs)
  key_name = aws_key_pair.ssh.key_name # "example"
  # Full absolute path to the license file, on the machine executing Terraform, for Teleport Enterprise.
  # This license will be copied into AWS SSM and then pulled down on the auth nodes to enable Enterprise functionality
  license_path = "" # "/path/to/license"
  # AMI name contains the version of Teleport to install, and whether to use OSS or Enterprise version
  # These AMIs are published by Teleport and shared as public whenever a new version of Teleport is released
  # To list available AMIs:
  # OSS: aws ec2 describe-images --owners 126027368216 --filters 'Name=name,Values=gravitational-teleport-ami-oss*'
  # Enterprise: aws ec2 describe-images --owners 126027368216 --filters 'Name=name,Values=gravitational-teleport-ami-ent*'
  # FIPS 140-2 images are also available for Enterprise customers, look for '-fips' on the end of the AMI's name
  ami_name = "gravitational-teleport-ami-oss-9.0.3"
  # Route 53 hosted zone to use, must be a root zone registered in AWS, e.g. example.com
  route53_zone = "${var.environment.name}.module.global_variables.org_domain_name" # "example.com"
  # Subdomain to set up in the zone above, e.g. cluster.example.com
  # This will be used for users connecting to Teleport proxy
  route53_domain = "teleport.${var.environment.name}.${module.global_variables.org_domain_name}" #  "cluster.example.com"
  # Bucket name to store encrypted LetsEncrypt certificates.
  s3_bucket_name = "teleport.${var.environment.name}.${module.global_variables.org_domain_name}"
  # Email to be used for LetsEncrypt certificate registration process.
  email = "david.c.allen1971@gmail.com"
  # Set to true to use LetsEncrypt to provision certificates
  use_letsencrypt = false # true
  # Set to true to use ACM (Amazon Certificate Manager) to provision certificates
  # If you wish to use a pre-existing ACM certificate rather than having Terraform generate one for you, you can import it:
  # terraform import aws_acm_certificate.cert <certificate_arn>
  use_acm = true
  default_tags = merge(module.global_variables.default_tags, var.environment.default_tags)
}

# ---------------------------------------------------------------------------------------------------------------------
# Teleport test ec2 instance to join the teleport cluster
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "teleport-bastion-test" {
  ami           = data.aws_ami.centos-7.id
  instance_type = "t3a.nano"
  iam_instance_profile = aws_iam_instance_profile.teleport-test.name
  subnet_id              = module.vpc.private_subnets[module.global_variables.aws_zone_preferred_placement_index]
  vpc_security_group_ids = [aws_security_group.teleport-bastion-test.id]
  key_name               = aws_key_pair.ssh.key_name
  root_block_device {
    delete_on_termination = true
    encrypted             = true
  }
  disable_api_termination = var.environment.resource_deletion_protection
  user_data = data.template_file.teleport-test.rendered
  //  user_data = templatefile("${path.module}/ec2-test-user-data.yaml", {
  //    aws_ec2_instance_name                 = "${var.environment.resource_name_prefix}-test-02"
  //    aws_ec2_instance_fqdn                 = (module.global_variables.org_using_subdomains) ? "${var.environment.resource_name_prefix}-teleport-bastion-test.${var.environment.name}.${module.global_variables.org_domain_name}" : "${var.environment.resource_name_prefix}-teleport-bastion-test.${module.global_variables.org_domain_name}"
  //    aws_route53_enabled                   = "TRUE"
  //    aws_route53_direct_dns_update_enabled = module.global_variables.route53_direct_dns_update_enabled ? "TRUE" : "FALSE"
  //    aws_route53_private_hosted_zone_id    = module.dns[0].route53_private_hosted_zone_id
  //  })
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name = "${var.environment.resource_name_prefix}-teleport-bastion-test"
    # Zone        = var.aws_zones[0]
    Visibility  = "private"
    Application = "teleport-bastion-test"
  })
}

# Security group to allow all traffic
resource "aws_security_group" "teleport-bastion-test" {
  name        = "${var.environment.resource_name_prefix}-teleport-bastion-test"
  description = "Rancher managed (workload) cluster"
  vpc_id      = module.vpc.vpc_id
  ingress {
//    from_port = "22"
//    to_port   = "22"
//    protocol  = "tcp"
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    cidr_blocks = concat(
      module.vpc.private_subnets_cidr_blocks,
      module.global_variables.allowed_org_private_network_cidrs,
      module.global_variables.allowed_org_vpn_cidrs
    )
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.global_variables.default_tags, {
    Name = "${var.environment.resource_name_prefix}-teleport-test"
  })
}
data "template_file" "teleport-test" {
  vars = {
    aws_ec2_instance_name                 = "${var.environment.resource_name_prefix}-teleport-test"
    aws_ec2_instance_fqdn                 = (module.global_variables.org_using_subdomains) ? "${var.environment.resource_name_prefix}-teleport-test.${var.environment.name}.${module.global_variables.org_domain_name}" : "${var.environment.resource_name_prefix}-teleport-test.${module.global_variables.org_domain_name}"
    aws_route53_enabled                   = "TRUE"
    aws_route53_direct_dns_update_enabled = module.global_variables.route53_direct_dns_update_enabled ? "TRUE" : "FALSE"
    aws_route53_private_hosted_zone_id    = module.dns[0].route53_private_hosted_zone_id
  }
  # Note the $${...} escaping so the above vars are used
  template = <<EOF
#cloud-config
preserve_hostname: false  # Feels wrong setting this to false, but otherwise will preserve the aws internal hostname "ip-99-99-99-99"
hostname: $${aws_ec2_instance_name}
fqdn: $${aws_ec2_instance_fqdn}
manage_etc_hosts: true

write_files:
  - path: /usr/local/bin/cloud-init-runcmd.sh
    permissions: '0700'
    content: |
      set -x
      # apt update
      # apt install -y software-properties-common
      # curl https://deb.releases.teleport.dev/teleport-pubkey.asc | sudo apt-key add -
      # add-apt-repository 'deb https://deb.releases.teleport.dev/ stable main'
      # apt-get install -y teleport
      # apt-get install -y dnsutils unzip    # Install dnsutils for dig and nslookup
      yum-config-manager --add-repo https://rpm.releases.teleport.dev/teleport.repo
      yum -y install bind-utils unzip teleport    # Install bind-utils for dig and nslookup
      #
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      ./aws/install
      if [ "$${aws_route53_enabled}" == "TRUE" ] ; then
      if [ "$${aws_route53_direct_dns_update_enabled}" == "TRUE" ] ; then
      PRPL_ROUTE53_PRIVATE_HOSTED_ZONE_ID=$${aws_route53_private_hosted_zone_id}
      PRIVATE_IP_ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')
      HOSTNAME=$(hostname)
      TTL="600"
      # Now register our hostname with Route53 DNS server ...
      aws route53 change-resource-record-sets --hosted-zone-id $$${PRPL_ROUTE53_PRIVATE_HOSTED_ZONE_ID} --change-batch "{ \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"$$${HOSTNAME}\", \"Type\": \"A\", \"TTL\": $$${TTL}, \"ResourceRecords\": [ { \"Value\": \"$$${PRIVATE_IP_ADDRESS}\" } ] } } ] }"
      fi
      fi
runcmd:
  - /usr/local/bin/cloud-init-runcmd.sh

output: {all: '| tee -a /var/log/cloud-init-output.log'}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for use by the test EC2 instance
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "teleport-test" {
  name                 = "${var.environment.resource_name_prefix}-teleport-test"
  max_session_duration = 43200
  assume_role_policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name = "${var.environment.resource_name_prefix}-teleport-test"
  })
}

# 2) Nexus get config files from S3
resource "aws_iam_policy" "teleport-test-route53" {
  name        = "${var.environment.resource_name_prefix}-teleport-test-route53"
  description = "Route53"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Route53registerDNS",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:route53:::hostedzone/${module.dns[0].route53_private_hosted_zone_id}"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "teleport-test-route53" {
  role       = aws_iam_role.teleport-test.name
  policy_arn = aws_iam_policy.teleport-test-route53.arn
}
resource "aws_iam_instance_profile" "teleport-test" {
  name  = "${var.environment.resource_name_prefix}-teleport-test"
  role  = aws_iam_role.teleport-test.name
}


//
//module "teleport-bastion" {
//  source = "../../../../../terraform-modules/terraform-module-aws-teleport-bastion-DIY"
//  # source                    = "git@github.com:davidcallen/terraform-module-aws-teleport-bastion-DIY.git?ref=1.0.0"
//  aws_region  = module.global_variables.aws_region
//  environment = var.environment
//  vpc_id      = module.vpc.vpc_id
//  //  vpc_public_subnet_ids         = module.vpc.public_subnets
//  //  vpc_public_subnet_cidrs       = module.vpc.public_subnets_cidr_blocks
//  vpc_private_subnet_ids   = module.vpc.private_subnets
//  vpc_private_subnet_cidrs = module.vpc.private_subnets_cidr_blocks
//  ec2_instance_ami_id      = data.aws_ami.ubuntu_20_04.id
//  ec2_instance_type        = "t3a.small"
//  ec2_ssh_key_pair_name    = aws_key_pair.ssh.key_name
//  ingress_allowed_cidrs = concat(
//    module.vpc.private_subnets_cidr_blocks,
//    module.global_variables.allowed_org_private_network_cidrs,
//    module.global_variables.allowed_org_vpn_cidrs
//  )
//}

//resource "aws_instance" "teleport-bastion" {
//  ami                  = data.aws_ami.ubuntu_20_04.id
//  instance_type        = "t3a.small"
//  # iam_instance_profile = aws_iam_instance_profile.test[0].name
//  subnet_id            = module.vpc.private_subnets[module.global_variables.aws_zone_preferred_placement_index]
//  vpc_security_group_ids = [aws_security_group.test.id]
//  key_name = var.ec2_ssh_key_pair_name
//  root_block_device {
//    delete_on_termination = true
//    encrypted             = true
//  }
//  disable_api_termination = var.environment.resource_deletion_protection
//  user_data = templatefile("${path.module}/ec2-test-user-data.yaml", {
//    aws_ec2_instance_name                 = "${var.environment.resource_name_prefix}-test-02"
//    aws_ec2_instance_fqdn                 = (var.org_using_subdomains) ? "${var.environment.resource_name_prefix}-test-02.${var.environment.name}.${var.org_domain_name}" : "${var.environment.resource_name_prefix}-test-02.${var.org_domain_name}"
//    aws_route53_enabled                   = "TRUE"
//    aws_route53_direct_dns_update_enabled = var.route53_direct_dns_update_enabled ? "TRUE" : "FALSE"
//    aws_route53_private_hosted_zone_id    = aws_route53_zone.private.id
//  })
//  tags = merge(var.default_tags, var.environment.default_tags, {
//    Name        = "${var.environment.resource_name_prefix}-test-02"
//    Zone        = var.aws_zones[0]
//    Visibility  = "private"
//    Application = "ec2-test"
//  })
//}
//
//# Security group to allow all traffic
//resource "aws_security_group" "teleport-bastion" {
//  name        = "${var.environment.resource_name_prefix}-teleport-test"
//  description = "Rancher managed (workload) cluster"
//  vpc_id      = var.vpc_id
//  ingress {
//    from_port   = "0"
//    to_port     = "0"
//    protocol    = "-1"
//    cidr_blocks = var.cluster_ingress_allowed_cidrs
//  }
//  egress {
//    from_port   = "0"
//    to_port     = "0"
//    protocol    = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  tags = merge(var.global_default_tags, {
//    Name = "${var.environment.resource_name_prefix}-teleport-test"
//  })
//}
//output "ec2_test_02_ip_address" {
//  value = (var.route53_testing_mode_enabled) ? aws_instance.test-02[0].private_ip : ""
//}