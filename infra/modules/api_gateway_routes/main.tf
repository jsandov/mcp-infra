# ---------------------------------------------------------------------------
# API Gateway Routes Module — main.tf
# Per-service route isolation for shared API Gateway (AC-6, SC-7)
# ---------------------------------------------------------------------------
# Each service team uses their own instance of this module to manage routes
# independently. One team's `tofu apply` cannot modify another team's routes.

locals {
  # Extract unique route paths for scoped Lambda permissions
  route_paths = distinct([
    for key, _ in var.routes : regex("^[A-Z]+ (/.+)$", key)[0]
  ])
}

# ---------------------------------------------------------------------------
# Lambda Integration (one per service backend)
# ---------------------------------------------------------------------------
# A single integration connects the API Gateway to this service's Lambda.
# All routes defined in this module share this integration.

resource "aws_apigatewayv2_integration" "this" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = var.payload_format_version
}

# ---------------------------------------------------------------------------
# Routes (one per route key, via for_each)
# ---------------------------------------------------------------------------
# Each route is independently addressable in state. Adding or removing a
# route from the map only affects that specific route — other routes in
# this module and all routes in other service modules are untouched.

resource "aws_apigatewayv2_route" "this" {
  for_each = var.routes

  api_id    = var.api_id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"

  authorization_type   = each.value.authorization_type
  authorizer_id        = each.value.authorizer_id
  authorization_scopes = each.value.authorization_scopes

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Lambda Permission (allows API Gateway to invoke the Lambda)
# ---------------------------------------------------------------------------
# One permission per unique route path. The statement_id includes the
# service_name to prevent collisions when multiple services grant API
# Gateway permission to invoke different Lambda functions.

resource "aws_lambda_permission" "this" {
  for_each = toset(local.route_paths)

  statement_id  = "AllowAPIGW-${var.service_name}${replace(each.value, "/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*${each.value}"
}
