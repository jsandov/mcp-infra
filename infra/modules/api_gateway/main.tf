# -----------------------------------------------------------------------------
# API Gateway v2 (HTTP API)
# -----------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.environment}-${var.name}"
  description   = var.description
  protocol_type = "HTTP"

  dynamic "cors_configuration" {
    for_each = var.enable_cors ? [1] : []
    content {
      allow_origins     = var.cors_allowed_origins
      allow_methods     = var.cors_allowed_methods
      allow_headers     = var.cors_allowed_headers
      expose_headers    = var.cors_expose_headers
      max_age           = var.cors_max_age
      allow_credentials = var.cors_allow_credentials
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Default Stage with Access Logging and Throttling
# -----------------------------------------------------------------------------

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = var.enable_auto_deploy

  dynamic "access_log_settings" {
    for_each = var.enable_access_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api[0].arn
      format = jsonencode({
        requestId               = "$context.requestId"
        ip                      = "$context.identity.sourceIp"
        requestTime             = "$context.requestTime"
        httpMethod              = "$context.httpMethod"
        routeKey                = "$context.routeKey"
        status                  = "$context.status"
        protocol                = "$context.protocol"
        responseLength          = "$context.responseLength"
        integrationErrorMessage = "$context.integrationErrorMessage"
      })
    }
  }

  default_route_settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
  }

  # Per-route throttle overrides for noisy-neighbor protection
  dynamic "route_settings" {
    for_each = var.route_throttle_overrides
    content {
      route_key              = route_settings.key
      throttling_rate_limit  = route_settings.value.throttling_rate_limit
      throttling_burst_limit = route_settings.value.throttling_burst_limit
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-default-stage"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group for Access Logs (FedRAMP AU-2, AU-3, AU-9)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "api" {
  count = var.enable_access_logging ? 1 : 0

  name              = "/aws/apigateway/${var.environment}-${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-access-logs"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

# -----------------------------------------------------------------------------
# VPC Link (conditional — for private backend integration, FedRAMP SC-7)
# -----------------------------------------------------------------------------

resource "aws_apigatewayv2_vpc_link" "this" {
  count = length(var.vpc_link_subnet_ids) > 0 ? 1 : 0

  name               = "${var.environment}-${var.name}-vpc-link"
  subnet_ids         = var.vpc_link_subnet_ids
  security_group_ids = var.vpc_link_security_group_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-vpc-link"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

# -----------------------------------------------------------------------------
# WAF Association (conditional — Layer 7 protection, FedRAMP SC-7)
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl_association" "this" {
  count = var.waf_acl_arn != null ? 1 : 0

  resource_arn = aws_apigatewayv2_stage.default.arn
  web_acl_arn  = var.waf_acl_arn
}

# -----------------------------------------------------------------------------
# Shared JWT Authorizer (conditional — centralized authentication, IA-2)
# -----------------------------------------------------------------------------
# When enabled, provides a single JWT authorizer that all service route modules
# can reference. This centralizes authentication policy on the shared gateway
# instead of each service team creating their own authorizer.

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.enable_jwt_authorizer ? 1 : 0

  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.environment}-${var.name}-jwt"

  jwt_configuration {
    issuer   = var.jwt_issuer
    audience = var.jwt_audience
  }
}
