# ---------------------------------------------------------------------------------------------------------------------
# Alarm SNS Topic
# ---------------------------------------------------------------------------------------------------------------------
module "cloudwatch_alarms_sns_topic" {
  # source                        = "git@github.com:davidcallen/terraform-module-sns-topic-subs.git?ref=1.0.0"
  source        = "../../../../../terraform-modules/terraform-module-sns-topic-subs"
  name          = "${var.environment.resource_name_prefix}-it-admin-alert"
  aws_region    = module.global_variables.aws_region
  alert_mobiles = []
  alert_emails  = var.environment.cloudwatch_alarms_sns_emails
  default_tags  = merge(module.global_variables.default_tags, var.environment.default_tags)
}

# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch Logs Alarm for cloud-init
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cloud-init" {
  name              = "cloud-init"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "cloud-init"
    Application = "cloud-init"
  })
}
resource "aws_cloudwatch_log_group" "cloud-init-output" {
  name              = "cloud-init-output"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "cloud-init-output"
    Application = "cloud-init"
  })
}
resource "aws_cloudwatch_query_definition" "cloud-init-output" {
  name            = "${var.environment.resource_name_prefix}-logs-cloud-init-output-errors"
  log_group_names = [aws_cloudwatch_log_group.cloud-init-output.name]
  query_string    = <<EOF
fields @timestamp, @message
| filter @message like ": ERROR :"
| sort @timestamp asc
| limit 25
EOF
}
resource "aws_cloudwatch_log_metric_filter" "cloud-init-output-errors" {
  name           = "${var.environment.resource_name_prefix}-logs-cloud-init-output-errors"
  pattern        = "\" : ERROR : \""
  log_group_name = aws_cloudwatch_log_group.cloud-init-output.name
  metric_transformation {
    name      = "${var.environment.resource_name_prefix}-logs-cloud-init-output-errors"
    namespace = "${module.global_variables.org_domain_name}/cloud-init"
    value     = "1"
  }
}
resource "aws_cloudwatch_metric_alarm" "cloud-init-output-errors" {
  alarm_name        = "${var.environment.resource_name_prefix}-alarm-logs-cloud-init-output-errors"
  alarm_description = "Errors found in Cloudwatch Log Group 'cloud-init-output'"
  namespace         = aws_cloudwatch_log_metric_filter.cloud-init-output-errors.metric_transformation[0].namespace
  metric_name       = aws_cloudwatch_log_metric_filter.cloud-init-output-errors.metric_transformation[0].name
  statistic         = "Maximum"
  period            = "60"
  # seconds (allowed are : 10, 30, 60, 360, 900,...)
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "0"
  evaluation_periods        = 1
  dimensions                = {}
  alarm_actions             = [module.cloudwatch_alarms_sns_topic.sns_topic.arn]
  ok_actions                = [module.cloudwatch_alarms_sns_topic.sns_topic.arn]
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name = "${var.environment.resource_name_prefix}-logs-cloud-init-output-errors"
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# Standard Cloudwatch LogGroups
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "system" {
  name              = "system"
  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
  tags = merge(module.global_variables.default_tags, var.environment.default_tags, {
    Name        = "system"
    Application = "cloud-init"
  })
}
