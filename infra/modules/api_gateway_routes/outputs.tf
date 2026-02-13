# ---------------------------------------------------------------------------
# API Gateway Routes Module — outputs.tf
# ---------------------------------------------------------------------------

output "integration_id" {
  description = "The ID of the API Gateway Lambda integration for this service."
  value       = aws_apigatewayv2_integration.this.id
}

output "route_ids" {
  description = "Map of route key to API Gateway route ID."
  value = {
    for key, route in aws_apigatewayv2_route.this : key => route.id
  }
}

output "route_keys" {
  description = "List of route keys managed by this module instance."
  value       = keys(var.routes)
}
