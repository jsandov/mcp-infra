# =============================================================================
# API Gateway Platform — Shared HTTP API for Multi-Team Service Routing
# =============================================================================
#
# This example demonstrates how a platform team deploys a shared API Gateway v2
# HTTP API that multiple service teams can independently attach routes to. Each
# service team manages their own routes in isolated state via the
# api_gateway_routes module, referencing outputs from this stack.
#
# Architecture:
#   Platform team (this stack) --> Shared API Gateway v2 (HTTP API)
#   Service team A (separate state) --> Routes for /service-a/*
#   Service team B (separate state) --> Routes for /service-b/*
#
# Limitations:
#   - WAFv2 is NOT supported on API Gateway v2 HTTP APIs. For Layer 7
#     protection, place a CloudFront distribution in front of the API and
#     attach a WAFv2 Web ACL to the CloudFront distribution instead.
#   - HTTP API v2 has a hard 30-second integration timeout. Workloads that
#     require longer execution should use REST API (v1) or asynchronous
#     invocation patterns (e.g., Step Functions, SQS).
# =============================================================================

# -----------------------------------------------------------------------------
# KMS Key — Encryption for API Gateway CloudWatch Access Logs
# -----------------------------------------------------------------------------

module "api_gateway_log_key" {
  source = "../../modules/kms"

  alias_name                    = "api-gateway-logs"
  description                   = "KMS key for encrypting API Gateway access logs"
  environment                   = var.environment
  enable_cloudwatch_logs_access = true

  tags = merge(var.tags, {
    Project = "api-gateway-platform"
  })
}

# -----------------------------------------------------------------------------
# Shared API Gateway v2 (HTTP API)
# -----------------------------------------------------------------------------
#
# This is the centrally managed API Gateway that all service teams share.
# Service teams attach routes via the api_gateway_routes module, referencing
# the api_id, execution_arn, and authorizer_id outputs from this stack.
#
# NOTE on WAF: AWS WAFv2 does NOT support API Gateway v2 HTTP APIs.
# For Layer 7 protection (FedRAMP SC-7), deploy a CloudFront distribution
# in front of this API and attach a WAFv2 Web ACL to the CloudFront
# distribution. See:
# https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vs-rest.html

module "api_gateway" {
  source = "../../modules/api_gateway"

  name        = "shared-platform-api"
  description = "Shared HTTP API Gateway managed by the platform team"
  environment = var.environment

  # Stage and deployment
  enable_auto_deploy = true

  # Access logging with KMS encryption (FedRAMP AU-2, AU-3, AU-9)
  enable_access_logging = true
  log_retention_days    = 90
  kms_key_arn           = module.api_gateway_log_key.key_arn

  # CORS configuration
  enable_cors          = true
  cors_allowed_origins = var.cors_allowed_origins
  cors_allowed_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  cors_allowed_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
  cors_max_age         = 86400

  # Shared JWT authorizer (FedRAMP IA-2)
  enable_jwt_authorizer = true
  jwt_issuer            = var.jwt_issuer
  jwt_audience          = var.jwt_audience

  # Default stage throttling
  throttling_rate_limit  = 1000
  throttling_burst_limit = 500

  # Per-route throttle overrides for noisy-neighbor protection.
  # Service teams request quota changes through the platform team.
  route_throttle_overrides = {
    "POST /service-a/execute" = {
      throttling_rate_limit  = 100
      throttling_burst_limit = 50
    }
    "GET /service-b/status" = {
      throttling_rate_limit  = 200
      throttling_burst_limit = 100
    }
  }

  # WAF is intentionally NOT configured here.
  # WAFv2 does not support HTTP API v2. Use CloudFront + WAF instead.
  waf_acl_arn = null

  # VPC Link is not enabled by default. To enable private backend integration,
  # uncomment the lines below and provide subnet/security-group IDs from a
  # networking stack:
  #
  # vpc_link_subnet_ids         = data.terraform_remote_state.networking.outputs.private_subnet_ids
  # vpc_link_security_group_ids = [module.vpc_link_sg.security_group_id]

  tags = merge(var.tags, {
    Project = "api-gateway-platform"
  })
}
