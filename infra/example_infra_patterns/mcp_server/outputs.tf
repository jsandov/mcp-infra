# ---------------------------------------------------------------------------
# MCP Server Module — outputs.tf
# ---------------------------------------------------------------------------

output "mcp_endpoint_url" {
  description = "Full URL of the MCP JSON-RPC endpoint (POST/GET/DELETE /mcp)"
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/mcp"
}

output "api_id" {
  description = "ID of the API Gateway v2 HTTP API"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Base endpoint URL of the API Gateway v2 HTTP API"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "lambda_function_arn" {
  description = "ARN of the MCP server Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Name of the MCP server Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda.name
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool (null if auth is disabled or using external pool)"
  value       = local.use_external_cognito ? var.cognito_user_pool_id : try(aws_cognito_user_pool.this[0].id, null)
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint of the Cognito user pool for JWT token issuance (null if auth is disabled)"
  value       = local.use_external_cognito ? var.cognito_user_pool_endpoint : try(aws_cognito_user_pool.this[0].endpoint, null)
}

output "cognito_client_id" {
  description = "Client ID of the Cognito user pool client (null if auth is disabled or using external pool)"
  value       = local.use_external_cognito ? var.cognito_client_id : try(aws_cognito_user_pool_client.this[0].id, null)
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for the MCP server container image (null if ECR is disabled)"
  value       = try(aws_ecr_repository.this[0].repository_url, null)
}

output "session_table_name" {
  description = "Name of the DynamoDB session table (null if sessions are disabled)"
  value       = try(aws_dynamodb_table.sessions[0].name, null)
}

output "session_table_arn" {
  description = "ARN of the DynamoDB session table (null if sessions are disabled)"
  value       = try(aws_dynamodb_table.sessions[0].arn, null)
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "api_log_group_name" {
  description = "Name of the CloudWatch log group for the API Gateway access logs"
  value       = aws_cloudwatch_log_group.api.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for CloudWatch alarm notifications"
  value       = local.alarm_sns_topic_arn
}

output "tenant_isolation_enabled" {
  description = "Whether Lambda tenant isolation mode is enabled"
  value       = var.enable_tenant_isolation
}

output "lambda_version" {
  description = "The latest published Lambda version (null if canary deployment is disabled)"
  value       = var.enable_canary_deployment ? aws_lambda_function.this.version : null
}

output "canary_alias_arn" {
  description = "ARN of the Lambda canary alias (null if canary deployment is disabled)"
  value       = try(aws_lambda_alias.canary[0].arn, null)
}
