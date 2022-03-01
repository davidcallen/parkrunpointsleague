
//# ---------------------------------------------------------------------------------------------------------------------
//# Cloudwatch for Logs - Log subscription only available on AWS Managed (full) AD
//# ---------------------------------------------------------------------------------------------------------------------
//resource "aws_cloudwatch_log_group" "simple-directory" {
//  name              = "/aws/directoryservice/${aws_directory_service_directory.simple-directory.id}"
//  retention_in_days = var.environment.cloudwatch_log_groups_default_retention_days
//}
//data "aws_iam_policy_document" "simple-directory-log-policy" {
//  statement {
//    actions = [
//      "logs:CreateLogStream",
//      "logs:PutLogEvents",
//    ]
//    principals {
//      identifiers = ["ds.amazonaws.com"]
//      type        = "Service"
//    }
//    resources = ["${aws_cloudwatch_log_group.simple-directory.arn}:*"]
//    effect    = "Allow"
//  }
//}
//resource "aws_cloudwatch_log_resource_policy" "simple-directory-log-policy" {
//  policy_document = data.aws_iam_policy_document.simple-directory-log-policy.json
//  policy_name     = "ad-log-policy"
//}