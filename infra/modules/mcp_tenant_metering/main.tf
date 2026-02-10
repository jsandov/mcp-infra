# ---------------------------------------------------------------------------
# MCP Tenant Metering Module — main.tf
# Per-tenant API usage tracking and monitoring (FedRAMP AU-2, SI-4, CM-7)
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.environment}-${var.name}"

  default_tags = {
    Name        = "${local.name_prefix}-metering"
    Environment = var.environment
    ManagedBy   = "opentofu"
  }

  tags = merge(local.default_tags, var.tags)

  alarm_sns_topic_arn = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : (
    length(aws_sns_topic.metering_alarms) > 0 ? aws_sns_topic.metering_alarms[0].arn : null
  )
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# DynamoDB Usage Table (AU-2)
# Tracks per-tenant API usage. The MCP server Lambda writes usage records
# here using the composite key (tenant_id, period).
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "usage" {
  name         = "${local.name_prefix}-mcp-usage"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenant_id"
  range_key    = "period"

  attribute {
    name = "tenant_id"
    type = "S"
  }

  attribute {
    name = "period"
    type = "S"
  }

  # GSI for cross-tenant reporting by period
  # (e.g., "which tenants used most this month?")
  global_secondary_index {
    name            = "period-index"
    hash_key        = "period"
    range_key       = "tenant_id"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# IAM Policy for Lambda to Write Usage Records
# Grants the MCP server Lambda role access to write to the usage table.
# ---------------------------------------------------------------------------

resource "aws_iam_role_policy" "usage_table_access" {
  name = "${local.name_prefix}-metering-dynamodb-access"
  role = var.lambda_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowUsageTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.usage.arn,
          "${aws_dynamodb_table.usage.arn}/index/*"
        ]
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# CloudWatch Log Metric Filters (SI-4)
# Extracts aggregate request counts from API Gateway access logs.
#
# NOTE: The actual tenant extraction depends on the access log format.
# For a Cognito JWT authorizer, the sub claim or a custom tenant_id claim
# would be in the authorizer context. Since the current mcp_server module
# logs $context.identity.sourceIp but not tenant context, this metric
# filter counts TOTAL requests per status code. The application-layer
# metering (DynamoDB writes) handles per-tenant counts.
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "request_count" {
  count = var.api_log_group_name != null ? 1 : 0

  name           = "${local.name_prefix}-mcp-request-count"
  log_group_name = var.api_log_group_name
  pattern        = "{ $.status = \"*\" }"

  metric_transformation {
    name          = "RequestCount"
    namespace     = var.metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  count = var.api_log_group_name != null ? 1 : 0

  name           = "${local.name_prefix}-mcp-error-count"
  log_group_name = var.api_log_group_name
  pattern        = "{ $.status = \"5*\" }"

  metric_transformation {
    name          = "ErrorCount"
    namespace     = var.metric_namespace
    value         = "1"
    default_value = 0
  }
}

# ---------------------------------------------------------------------------
# SNS Topic for Metering Alerts (IR-4)
# Created only if an external SNS topic ARN is not provided.
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "metering_alarms" {
  count = var.alarm_sns_topic_arn == null ? 1 : 0

  name              = "${local.name_prefix}-mcp-metering-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = local.tags
}

# ---------------------------------------------------------------------------
# CloudWatch Alarm: High Request Rate (CM-7)
# Alerts when total request rate exceeds the configured threshold.
# For per-tenant alarms, the MCP server application should publish custom
# metrics with a TenantId dimension.
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "high_request_rate" {
  count = var.enable_quota_alarm && var.api_log_group_name != null ? 1 : 0

  alarm_name          = "${local.name_prefix}-mcp-high-request-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.quota_alarm_evaluation_periods
  metric_name         = "RequestCount"
  namespace           = var.metric_namespace
  period              = var.quota_alarm_period
  statistic           = "Sum"
  threshold           = var.quota_request_threshold
  alarm_description   = "MCP API request rate exceeded quota threshold (FedRAMP CM-7, SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = true

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "CM-7" })
}

# ---------------------------------------------------------------------------
# CloudWatch Alarm: High Error Rate (SI-4)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  count = var.enable_quota_alarm && var.api_log_group_name != null ? 1 : 0

  alarm_name          = "${local.name_prefix}-mcp-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorCount"
  namespace           = var.metric_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "MCP API error rate exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = true

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}
