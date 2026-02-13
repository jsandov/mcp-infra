output "sns_topic_arn" {
  description = "The ARN of the SNS alarm notification topic"
  value       = aws_sns_topic.alarms.arn
}

output "sns_topic_name" {
  description = "The name of the SNS alarm notification topic"
  value       = aws_sns_topic.alarms.name
}

output "alb_5xx_alarm_arn" {
  description = "The ARN of the ALB 5xx error alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.alb_5xx[0].arn, null)
}

output "alb_unhealthy_alarm_arn" {
  description = "The ARN of the ALB unhealthy targets alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.alb_unhealthy_targets[0].arn, null)
}

output "apigw_5xx_alarm_arn" {
  description = "The ARN of the API Gateway 5xx alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.apigw_5xx[0].arn, null)
}

output "apigw_4xx_alarm_arn" {
  description = "The ARN of the API Gateway 4xx alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.apigw_4xx[0].arn, null)
}

output "apigw_latency_alarm_arn" {
  description = "The ARN of the API Gateway latency alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.apigw_latency[0].arn, null)
}

output "vpc_rejected_alarm_arn" {
  description = "The ARN of the VPC rejected packets alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.vpc_rejected_packets[0].arn, null)
}

output "lambda_concurrent_alarm_arn" {
  description = "The ARN of the Lambda concurrent executions alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.lambda_concurrent[0].arn, null)
}

output "dynamodb_throttle_alarm_arn" {
  description = "The ARN of the DynamoDB throttled requests alarm (null if disabled)"
  value       = try(aws_cloudwatch_metric_alarm.dynamodb_throttle[0].arn, null)
}
