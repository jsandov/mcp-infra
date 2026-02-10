# ---------------------------------------------------------------------------
# MCP Tenant Metering Module — outputs.tf
# ---------------------------------------------------------------------------

output "usage_table_name" {
  description = "Name of the DynamoDB usage tracking table. Use this to configure the MCP server Lambda environment."
  value       = aws_dynamodb_table.usage.name
}

output "usage_table_arn" {
  description = "ARN of the DynamoDB usage tracking table."
  value       = aws_dynamodb_table.usage.arn
}

output "metric_namespace" {
  description = "CloudWatch custom metric namespace for tenant metering. Use this when publishing per-tenant metrics from the MCP server."
  value       = var.metric_namespace
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for metering alerts. Either the externally provided topic or the one created by this module."
  value       = local.alarm_sns_topic_arn
}

output "request_count_metric_filter_name" {
  description = "Name of the CloudWatch metric filter for request counting. Null if no API log group is configured."
  value       = length(aws_cloudwatch_log_metric_filter.request_count) > 0 ? aws_cloudwatch_log_metric_filter.request_count[0].name : null
}

output "error_count_metric_filter_name" {
  description = "Name of the CloudWatch metric filter for error counting. Null if no API log group is configured."
  value       = length(aws_cloudwatch_log_metric_filter.error_count) > 0 ? aws_cloudwatch_log_metric_filter.error_count[0].name : null
}
