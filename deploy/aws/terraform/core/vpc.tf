# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source               = "github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v3.11.0"
  name                 = "${var.environment.resource_name_prefix}-vpc"
  cidr                 = var.vpc.cidr_block # Avoid overlaping cidrs within this account and our other org accounts
  azs                  = module.global_variables.aws_zones
  private_subnets      = var.vpc.private_subnets_cidr_blocks
  public_subnets       = var.vpc.public_subnets_cidr_blocks
  enable_nat_gateway   = true
  enable_vpn_gateway   = false # Using Transit Gateway instead
  enable_dns_hostnames = true
  enable_dns_support   = true

  //  enable_public_s3_endpoint             = false
  //  enable_s3_endpoint                    = true
  //  enable_dynamodb_endpoint              = true
  //  dynamodb_endpoint_private_dns_enabled = true

  # ---------- VPC Flow Logs to S3 ----------
  # Format = ${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}
  enable_flow_log                   = var.vpc.flow_logs_to_s3_enabled
  flow_log_destination_type         = "s3"
  flow_log_destination_arn          = (var.vpc.flow_logs_to_s3_enabled) ? module.vpc-flow-logs-s3[0].s3_bucket_arn : ""
  flow_log_traffic_type             = "REJECT" # REJECT | ACCEPT | ALL
  flow_log_max_aggregation_interval = 600      # 600 = 10 mins = fewer zips written to S3. 60 = more zips written
  vpc_flow_log_tags = {
    Name = "vpc-flow-logs"
  }

  //  # ---------- VPC Flow Logs (will create the cloudwatch_log_group) ----------
  //  # Can switch from S3 above to Cloudwatch if need more instantaneous debugging e.g. for Customer,
  //  # but S3 best for permanent log location since cheaper.
  //  enable_flow_log                                 = false
  //  flow_log_destination_type                       = "cloud-watch-logs"
  //  flow_log_traffic_type                           = "REJECT"# REJECT | ACCEPT | ALL
  //  flow_log_max_aggregation_interval               = 60         # 600 = 10 mins = fewer zips written to S3. 60 = more zips written
  //  flow_log_cloudwatch_iam_role_arn                = module.iam-vpc-flow-logs.vpc-flow-logs-role-arn
  //  create_flow_log_cloudwatch_log_group            = true
  //  flow_log_cloudwatch_log_group_name_prefix       = "${var.environment.resource_name_prefix}-vpc-flow-logs"
  //  flow_log_cloudwatch_log_group_retention_in_days = module.global_variables.cloudwatch_log_groups_default_retention_days
  //  vpc_flow_log_tags = {
  //    Name = "vpc-flow-logs-cloudwatch-logs"
  //  }

  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {})
  public_subnet_tags = {
    Visibility                                           = "public"
    "kubernetes.io/cluster/${var.environment.resource_name_prefix}-kube-jenkins-cluster" = "shared"
    "kubernetes.io/role/elb"                             = "1"
  }
  private_subnet_tags = {
    Visibility                                           = "private"
    "kubernetes.io/cluster/${var.environment.resource_name_prefix}-kube-jenkins-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                    = "1"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC Endpoint
# ---------------------------------------------------------------------------------------------------------------------
module "endpoints" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v3.11.0/modules/vpc-endpoints"
  vpc_id = module.vpc.vpc_id
  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway" # only the Gateway type is free for s3
      # security_group_ids = [aws_security_group.vpc-endpoints.id]
      # subnet_ids         = concat(module.vpc.public_subnets, module.vpc.private_subnets)
      route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids, module.vpc.database_route_table_ids)
      tags = {
        Name = "${var.environment.resource_name_prefix}-vpc-endpoint-s3"
      }
    },
    //    dynamodb = {
    //      # gateway endpoint
    //      service         = "dynamodb"
    //      route_table_ids = ["rt-12322456", "rt-43433343", "rt-11223344"]
    //      tags            = { Name = "dynamodb-vpc-endpoint" }
    //    }
  }
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {})
}
//# ---------------------------------------------------------------------------------------------------------------------
//# VPC Endpoint : Security Groups and Rules
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_security_group" "vpc-endpoints" {
//  name        = "${var.environment.resource_name_prefix}-vpc-endpoints"
//  description = "Security group for VPC Endpoints for this VPC and any of our TGW attached VPCs."
//  vpc_id      = module.vpc.vpc_id
//  tags = {
//    Name = "${var.environment.resource_name_prefix}-vpc-endpoints"
//  }
//}
//# All ingress from all our "cross-account" VPCs
//resource "aws_security_group_rule" "vpc-endpoints-allow-ingress" {
//  type              = "ingress"
//  description       = "vpc-endpoints"
//  from_port         = 0
//  to_port           = 65535
//  protocol          = "all"
//  cidr_blocks       = concat(module.global_variables.allowed_org_private_network_cidrs, module.global_variables.allowed_org_vpn_cidrs, [var.vpc.cidr_block])
//  security_group_id = aws_security_group.vpc-endpoints.id
//}
# ---------------------------------------------------------------------------------------------------------------------
# Shared Transit Gateway.
#  Note TGW is shared from Master account using AWS Resource Access Manager (RAM).
#  TGW has auto-accept attachments to facilitate automation.
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ec2_transit_gateway" "cross-account" {
  //  count             = (var.cross_account_access.enabled && var.cross_account_access.type == "SHARED_TRANSIT_GATEWAY") ? 1 : 0
  /*
    * Cant currently filter by owner_id
    filter {
      name   = "owner_id"
      values = [var.cross_account_access.backbone_account_id]
    }
    filter {
      name   = "vpc-id"
      values = [module.vpc.vpc_id]
    }
    filter {
      name      = "tag:Name"
      values    = ["backbone"]
    }
  */
}
resource "aws_ec2_transit_gateway_vpc_attachment" "cross-account" {
  //  count              = (var.cross_account_access.enabled && var.cross_account_access.type == "SHARED_TRANSIT_GATEWAY") ? 1 : 0
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = data.aws_ec2_transit_gateway.cross-account.id
  vpc_id             = module.vpc.vpc_id
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name = "${var.environment.resource_name_prefix}-tgw-vpc-attachment"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# Create extra routes for cross-account access : For SHARED_TRANSIT_GATEWAY
# ---------------------------------------------------------------------------------------------------------------------
locals {
  route_table_account_cidr_combination_pairs = setproduct(module.vpc.private_route_table_ids, var.cross_account_access.accounts[*].cidr_block)
}
resource "aws_route" "route-cross-account-shared-tgw" {
  //  count                     = (var.cross_account_access.enabled && var.cross_account_access.type == "SHARED_TRANSIT_GATEWAY") ? length(local.route_table_account_cidr_combination_pairs) : 0
  count                  = length(local.route_table_account_cidr_combination_pairs)
  route_table_id         = element(local.route_table_account_cidr_combination_pairs, count.index)[0]
  destination_cidr_block = element(local.route_table_account_cidr_combination_pairs, count.index)[1]
  # TODO : Need to create the TGW (and/or sharing and attachments) through terraform ideally (not manually at present)
  transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.cross-account.transit_gateway_id
}
//
//# ---------------------------------------------------------------------------------------------------------------------
//# Create extra routes for Customer account access : For SHARED_TRANSIT_GATEWAY
//# ---------------------------------------------------------------------------------------------------------------------
//locals {
//  route_table_customer_account_cidr_combination_pairs = setproduct(module.vpc.private_route_table_ids, var.customer_account_access.accounts[*].cidr_block)
//}
//resource "aws_route" "route-customer-account-shared-tgw" {
//  count                     = (var.customer_account_access.enabled && var.customer_account_access.type == "SHARED_TRANSIT_GATEWAY") ? length(local.route_table_customer_account_cidr_combination_pairs) : 0
//
//  route_table_id            = element(local.route_table_customer_account_cidr_combination_pairs, count.index)[0]
//  destination_cidr_block    = element(local.route_table_customer_account_cidr_combination_pairs, count.index)[1]
//  # TODO : Need to create the TGW (and/or sharing and attachments) through terraform ideally (not manually at present)
//  transit_gateway_id        = aws_ec2_transit_gateway_vpc_attachment.cross-account[0].transit_gateway_id
//}

# ---------------------------------------------------------------------------------------------------------------------
# Create extra routes for Allowed External Network access : For SHARED_TRANSIT_GATEWAY
# ---------------------------------------------------------------------------------------------------------------------
locals {
  route_table_external_networks_cidr_combination_pairs = setproduct(module.vpc.private_route_table_ids, module.global_variables.allowed_org_private_network_cidrs)
}
resource "aws_route" "route-external-networks-shared-tgw" {
  // count                     = (var.cross_account_access.enabled && var.cross_account_access.type == "SHARED_TRANSIT_GATEWAY") ? length(local.route_table_external_networks_cidr_combination_pairs) : 0
  count                  = length(local.route_table_external_networks_cidr_combination_pairs)
  route_table_id         = element(local.route_table_external_networks_cidr_combination_pairs, count.index)[0]
  destination_cidr_block = element(local.route_table_external_networks_cidr_combination_pairs, count.index)[1]
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.cross-account.transit_gateway_id
}
# ---------------------------------------------------------------------------------------------------------------------
# Create extra routes for Allowed VPN access : For SHARED_TRANSIT_GATEWAY
# ---------------------------------------------------------------------------------------------------------------------
locals {
  route_table_vpn_cidr_combination_pairs = setproduct(module.vpc.private_route_table_ids, module.global_variables.allowed_org_vpn_cidrs)
}
resource "aws_route" "route-vpn-shared-tgw" {
  // count                     = (module.global_variables.cross_account_access.enabled && module.global_variables.cross_account_access.type == "SHARED_TRANSIT_GATEWAY") ? length(local.route_table_external_networks_cidr_combination_pairs) : 0
  count                  = length(local.route_table_vpn_cidr_combination_pairs)
  route_table_id         = element(local.route_table_vpn_cidr_combination_pairs, count.index)[0]
  destination_cidr_block = element(local.route_table_vpn_cidr_combination_pairs, count.index)[1]
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.cross-account.transit_gateway_id
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 storage for VPC Flow Logs (long-term storage)
# ---------------------------------------------------------------------------------------------------------------------
module "vpc-flow-logs-s3" {
  # source     = "git@github.com:davidcallen/terraform-module-aws-vpc-flow-logs-s3.git?ref=1.0.0"
  source         = "../../../../../terraform-modules/terraform-module-aws-vpc-flow-logs-s3"
  count          = var.vpc.flow_logs_to_s3_enabled ? 1 : 0
  s3_bucket_name = "${module.global_variables.org_domain_name}-${var.environment.resource_name_prefix}-vpc-flow-logs"
  aws_region     = module.global_variables.aws_region
  account_id     = var.environment.account_id
  tags           = merge(module.global_variables.default_tags, var.environment.default_tags)
}