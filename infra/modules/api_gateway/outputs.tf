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

output "execution_arn" {
  description = "The execution ARN of the API Gateway, used for Lambda invoke permissions in route modules"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "authorizer_id" {
  description = "The ID of the shared JWT authorizer (null if no authorizer configured)"
  value       = try(aws_apigatewayv2_authorizer.jwt[0].id, null)
}

output "custom_domain_name" {
  description = "The custom domain name for the API Gateway (null if mTLS is disabled)"
  value       = try(aws_apigatewayv2_domain_name.mtls[0].domain_name, null)
}

output "custom_domain_target" {
  description = "The target domain name for DNS CNAME/alias records (null if mTLS is disabled)"
  value       = try(aws_apigatewayv2_domain_name.mtls[0].domain_name_configuration[0].target_domain_name, null)
}

output "custom_domain_hosted_zone_id" {
  description = "The Route53 hosted zone ID for the custom domain (null if mTLS is disabled)"
  value       = try(aws_apigatewayv2_domain_name.mtls[0].domain_name_configuration[0].hosted_zone_id, null)
}
