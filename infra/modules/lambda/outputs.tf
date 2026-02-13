output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "The invocation ARN for API Gateway integration"
  value       = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  description = "The ARN of the Lambda function with version qualifier"
  value       = aws_lambda_function.this.qualified_arn
}

output "role_arn" {
  description = "The ARN of the IAM execution role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "The name of the IAM execution role"
  value       = aws_iam_role.this.name
}

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}

output "version" {
  description = "The published version of the Lambda function (null if publish is false)"
  value       = var.publish ? aws_lambda_function.this.version : null
}

output "alias_arn" {
  description = "The ARN of the Lambda alias (null if alias is disabled)"
  value       = try(aws_lambda_alias.this[0].arn, null)
}

output "alias_invoke_arn" {
  description = "The invoke ARN of the Lambda alias for API Gateway integration (null if alias is disabled)"
  value       = try(aws_lambda_alias.this[0].invoke_arn, null)
}

output "function_url" {
  description = "The Lambda function URL for direct HTTPS invocation (null if disabled)"
  value       = try(aws_lambda_function_url.this[0].function_url, null)
}
