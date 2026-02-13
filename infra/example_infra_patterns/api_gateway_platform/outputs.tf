# =============================================================================
# Outputs — API Gateway Platform
# =============================================================================
#
# These outputs provide all values that downstream service teams need to
# attach routes to the shared API Gateway. Service teams should reference
# these via remote state or as input variables to their own stacks.
# =============================================================================

output "api_id" {
  description = "The ID of the shared API Gateway, used by service teams in the api_gateway_routes module"
  value       = module.api_gateway.api_id
}

output "api_endpoint" {
  description = "The default endpoint URL of the shared API Gateway (e.g., https://<api-id>.execute-api.<region>.amazonaws.com)"
  value       = module.api_gateway.api_endpoint
}

output "api_execution_arn" {
  description = "The execution ARN of the API Gateway, used for Lambda invoke permissions in service team route modules"
  value       = module.api_gateway.execution_arn
}

output "stage_invoke_url" {
  description = "The invocation URL of the default stage, used as the base URL for all API requests"
  value       = module.api_gateway.stage_invoke_url
}

output "authorizer_id" {
  description = "The ID of the shared JWT authorizer, passed to service team route modules for authorization"
  value       = module.api_gateway.authorizer_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for API Gateway log encryption"
  value       = module.api_gateway_log_key.key_arn
}
