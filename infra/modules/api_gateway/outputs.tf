output "api_id" {
  description = "The ID of the API Gateway"
  value       = aws_apigatewayv2_api.this.id
}

output "api_arn" {
  description = "The ARN of the API Gateway"
  value       = aws_apigatewayv2_api.this.arn
}

output "api_endpoint" {
  description = "The default endpoint URL of the API"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "stage_id" {
  description = "The ID of the default stage"
  value       = aws_apigatewayv2_stage.default.id
}

output "stage_invoke_url" {
  description = "The invocation URL of the default stage"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "cloudwatch_log_group_name" {
  description = "The CloudWatch Log Group name for API access logs (null if logging disabled)"
  value       = try(aws_cloudwatch_log_group.api[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "The CloudWatch Log Group ARN for API access logs (null if logging disabled)"
  value       = try(aws_cloudwatch_log_group.api[0].arn, null)
}

output "vpc_link_id" {
  description = "The ID of the VPC Link (null if no VPC Link created)"
  value       = try(aws_apigatewayv2_vpc_link.this[0].id, null)
}

output "execution_role_arn" {
  description = "The ARN of the IAM role used for CloudWatch logging (null if logging disabled)"
  value       = try(aws_iam_role.api_logging[0].arn, null)
}
