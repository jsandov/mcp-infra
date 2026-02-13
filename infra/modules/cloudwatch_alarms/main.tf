# -----------------------------------------------------------------------------
# SNS Topic for Alarm Notifications
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "alarms" {
  name              = "${var.environment}-${var.name}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-alarms"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

# -----------------------------------------------------------------------------
# ALB 5xx Error Rate Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = var.enable_alb_5xx_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.alb_5xx_period
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB 5xx error count exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-alb-5xx"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}

# -----------------------------------------------------------------------------
# ALB Unhealthy Targets Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  count = var.enable_alb_unhealthy_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alb_unhealthy_evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.alb_unhealthy_period
  statistic           = "Maximum"
  threshold           = var.alb_unhealthy_threshold
  alarm_description   = "ALB unhealthy target count exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = var.alb_target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-alb-unhealthy-targets"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}

# -----------------------------------------------------------------------------
# API Gateway 5xx Error Rate Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  count = var.enable_apigw_5xx_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-apigw-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.apigw_5xx_evaluation_periods
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = var.apigw_5xx_period
  statistic           = "Sum"
  threshold           = var.apigw_5xx_threshold
  alarm_description   = "API Gateway 5xx error count exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.apigw_api_id
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-apigw-5xx"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}

# -----------------------------------------------------------------------------
# API Gateway 4xx Error Rate Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "apigw_4xx" {
  count = var.enable_apigw_4xx_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-apigw-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.apigw_4xx_evaluation_periods
  metric_name         = "4xx"
  namespace           = "AWS/ApiGateway"
  period              = var.apigw_4xx_period
  statistic           = "Sum"
  threshold           = var.apigw_4xx_threshold
  alarm_description   = "API Gateway 4xx error count exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.apigw_api_id
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-apigw-4xx"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}

# -----------------------------------------------------------------------------
# API Gateway Latency Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "apigw_latency" {
  count = var.enable_apigw_latency_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-apigw-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.apigw_latency_evaluation_periods
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = var.apigw_latency_period
  extended_statistic  = "p99"
  threshold           = var.apigw_latency_threshold
  alarm_description   = "API Gateway p99 latency exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.apigw_api_id
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-apigw-latency"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}

# -----------------------------------------------------------------------------
# Lambda ConcurrentExecutions Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent" {
  count = var.enable_lambda_concurrent_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-lambda-concurrent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.lambda_concurrent_evaluation_periods
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = var.lambda_concurrent_period
  statistic           = "Maximum"
  threshold           = var.lambda_concurrent_threshold
  alarm_description   = "Lambda concurrent executions approaching limit (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-lambda-concurrent"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}

# -----------------------------------------------------------------------------
# DynamoDB ThrottledRequests Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  count = var.enable_dynamodb_throttle_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-dynamodb-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.dynamodb_throttle_evaluation_periods
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = var.dynamodb_throttle_period
  statistic           = "Sum"
  threshold           = var.dynamodb_throttle_threshold
  alarm_description   = "DynamoDB table throttling detected (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = var.dynamodb_table_name
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-dynamodb-throttle"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}

# -----------------------------------------------------------------------------
# VPC Flow Logs Rejected Packets Metric Filter
# -----------------------------------------------------------------------------

# VPC Flow Logs do not publish metrics to CloudWatch natively. This metric
# filter extracts rejected packet counts from the flow log group so the
# alarm below has actual data to evaluate.
resource "aws_cloudwatch_log_metric_filter" "vpc_rejected_packets" {
  count = var.enable_vpc_rejected_alarm && var.vpc_flow_log_group_name != "" ? 1 : 0

  name           = "${var.environment}-${var.name}-vpc-rejected-packets"
  log_group_name = var.vpc_flow_log_group_name
  pattern        = "[version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, start, end, action=\"REJECT\", log_status]"

  metric_transformation {
    name          = "RejectedPackets"
    namespace     = "CustomVPCMetrics"
    value         = "$packets"
    default_value = 0
  }
}

# -----------------------------------------------------------------------------
# VPC Flow Logs Rejected Packets Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "vpc_rejected_packets" {
  count = var.enable_vpc_rejected_alarm ? 1 : 0

  alarm_name          = "${var.environment}-${var.name}-vpc-rejected-packets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.vpc_rejected_evaluation_periods
  threshold           = var.vpc_rejected_threshold
  alarm_description   = "VPC Flow Logs rejected packet count exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "rejected"
    return_data = true

    metric {
      metric_name = "RejectedPackets"
      namespace   = "CustomVPCMetrics"
      period      = var.vpc_rejected_period
      stat        = "Sum"

      dimensions = {
        LogGroupName = var.vpc_flow_log_group_name
      }
    }
  }

  alarm_actions = compact([
    aws_sns_topic.alarms.arn,
    var.remediation_lambda_arn,
  ])

  ok_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-vpc-rejected-packets"
    Environment = var.environment
    ManagedBy   = "opentofu"
    FedRAMP     = "SI-4"
  })
}
