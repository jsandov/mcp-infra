# ---------------------------------------------------------------------------
# MCP Server Module — main.tf
# FedRAMP-compliant MCP (Model Context Protocol) server on AWS Lambda
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.environment}-${var.name}"

  default_tags = {
    Name        = "${local.name_prefix}-mcp"
    Environment = var.environment
    ManagedBy   = "opentofu"
  }

  tags = merge(local.default_tags, var.tags)

  # Cognito resolution — external vs. internally created
  use_external_cognito = var.cognito_user_pool_id != null
  create_cognito       = var.enable_auth && !local.use_external_cognito

  cognito_issuer = local.use_external_cognito ? "https://${var.cognito_user_pool_endpoint}" : (
    local.create_cognito ? "https://${aws_cognito_user_pool.this[0].endpoint}" : null
  )
  cognito_audience = local.use_external_cognito ? [var.cognito_client_id] : (
    local.create_cognito ? [aws_cognito_user_pool_client.this[0].id] : null
  )

  lambda_environment_variables = merge(
    var.environment_variables,
    var.enable_session_table ? { SESSION_TABLE_NAME = aws_dynamodb_table.sessions[0].name } : {},
    var.enable_tenant_isolation ? { TENANT_ISOLATION_ENABLED = "true" } : {}
  )

  alarm_sns_topic_arn = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : (
    length(aws_sns_topic.alarms) > 0 ? aws_sns_topic.alarms[0].arn : null
  )
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Authentication — Cognito (IA-2, IA-8)
# ---------------------------------------------------------------------------

resource "aws_cognito_user_pool" "this" {
  count = local.create_cognito ? 1 : 0

  name                = "${local.name_prefix}-mcp"
  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

  tags = local.tags
}

resource "aws_cognito_user_pool_domain" "this" {
  count = local.create_cognito ? 1 : 0

  domain       = "${local.name_prefix}-mcp"
  user_pool_id = aws_cognito_user_pool.this[0].id
}

resource "aws_cognito_resource_server" "this" {
  count = local.create_cognito ? 1 : 0

  identifier   = "mcp"
  name         = "${local.name_prefix}-mcp-resource-server"
  user_pool_id = aws_cognito_user_pool.this[0].id

  scope {
    scope_name        = "invoke"
    scope_description = "Invoke MCP tools"
  }
}

resource "aws_cognito_user_pool_client" "this" {
  count = local.create_cognito ? 1 : 0

  name                                 = "${local.name_prefix}-mcp-client"
  user_pool_id                         = aws_cognito_user_pool.this[0].id
  allowed_oauth_flows                  = ["client_credentials"]
  generate_secret                      = true
  allowed_oauth_scopes                 = ["mcp/invoke"]
  allowed_oauth_flows_user_pool_client = true

  depends_on = [aws_cognito_resource_server.this]
}

# ---------------------------------------------------------------------------
# IAM (AC-6)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-mcp-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

# Basic execution role for CloudWatch Logs access
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access execution role — required because Lambda runs in private subnets
resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# X-Ray tracing permissions (SI-4)
resource "aws_iam_role_policy_attachment" "xray" {
  count = var.enable_xray_tracing ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# KMS access for decrypting environment variables and log groups (SC-12, SC-13)
# Only created when a customer-managed KMS key is provided.
resource "aws_iam_role_policy" "kms_access" {
  count = var.kms_key_arn != null ? 1 : 0

  name = "${local.name_prefix}-mcp-kms-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ]
      Resource = [var.kms_key_arn]
    }]
  })
}

# DynamoDB access for session management (conditional)
# When tenant isolation is enabled, the IAM policy uses dynamodb:LeadingKeys
# to restrict each tenant to their own partition key prefix. The tenant_id
# is extracted from JWT claims by the Lambda runtime.
resource "aws_iam_role_policy" "dynamodb_access" {
  count = var.enable_session_table && !var.enable_tenant_isolation ? 1 : 0

  name = "${local.name_prefix}-mcp-dynamodb-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query"
      ]
      Resource = [aws_dynamodb_table.sessions[0].arn]
    }]
  })
}

# DynamoDB access with tenant isolation — scoped by LeadingKeys (FedRAMP AC-6)
resource "aws_iam_role_policy" "dynamodb_tenant_access" {
  count = var.enable_session_table && var.enable_tenant_isolation ? 1 : 0

  name = "${local.name_prefix}-mcp-dynamodb-tenant-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query"
      ]
      Resource = [
        aws_dynamodb_table.sessions[0].arn,
        "${aws_dynamodb_table.sessions[0].arn}/index/session-id-index"
      ]
      Condition = {
        "ForAllValues:StringEquals" = {
          "dynamodb:LeadingKeys" = ["$${aws:PrincipalTag/tenant_id}"]
        }
      }
    }]
  })
}

# ---------------------------------------------------------------------------
# CloudWatch Log Groups (AU-2, AU-3)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}-mcp"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${local.name_prefix}-mcp"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Lambda Function (SC-28, CM-7)
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = "${local.name_prefix}-mcp"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = var.image_uri
  memory_size   = var.memory_size
  timeout       = var.timeout
  kms_key_arn   = var.kms_key_arn
  publish       = var.enable_canary_deployment

  reserved_concurrent_executions = var.reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  # Tenant isolation — per-tenant Firecracker VM isolation (FedRAMP SC-7)
  dynamic "tenancy_config" {
    for_each = var.enable_tenant_isolation ? [1] : []
    content {
      tenant_isolation_mode = "PER_TENANT"
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  dynamic "environment" {
    for_each = length(local.lambda_environment_variables) > 0 ? [1] : []
    content {
      variables = local.lambda_environment_variables
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Lambda Alias — Canary Routing (conditional)
# ---------------------------------------------------------------------------

resource "aws_lambda_alias" "canary" {
  count = var.enable_canary_deployment ? 1 : 0

  name             = var.canary_alias_name
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version

  dynamic "routing_config" {
    for_each = var.canary_version != null && var.canary_weight > 0 ? [1] : []
    content {
      additional_version_weights = {
        (var.canary_version) = var.canary_weight
      }
    }
  }
}

# ---------------------------------------------------------------------------
# API Gateway v2 — HTTP API (SC-7, SC-8)
# ---------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name_prefix}-mcp"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins  = var.cors_allowed_origins
    allow_methods  = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers  = ["Content-Type", "Authorization", "Mcp-Session-Id"]
    expose_headers = ["Mcp-Session-Id"]
    max_age        = 86400
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
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
      authorizer_claims_sub   = "$context.authorizer.claims.sub"
      authorizer_claims_tid   = "$context.authorizer.claims.custom:tenant_id"
    })
  }

  default_route_settings {
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
  }

  # Per-route throttle overrides
  dynamic "route_settings" {
    for_each = var.route_throttle_overrides
    content {
      route_key              = route_settings.key
      throttling_rate_limit  = route_settings.value.throttling_rate_limit
      throttling_burst_limit = route_settings.value.throttling_burst_limit
    }
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Custom Domain with mTLS (conditional — machine-to-machine auth, IA-2)
# ---------------------------------------------------------------------------

resource "aws_apigatewayv2_domain_name" "mtls" {
  count = var.enable_mtls ? 1 : 0

  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = var.mtls_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  mutual_tls_authentication {
    truststore_uri     = var.mtls_truststore_uri
    truststore_version = var.mtls_truststore_version
  }

  tags = local.tags
}

resource "aws_apigatewayv2_api_mapping" "mtls" {
  count = var.enable_mtls ? 1 : 0

  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.mtls[0].id
  stage       = aws_apigatewayv2_stage.default.id
}

# Cognito JWT authorizer (IA-2)
resource "aws_apigatewayv2_authorizer" "cognito" {
  count = var.enable_auth ? 1 : 0

  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name_prefix}-cognito"

  jwt_configuration {
    issuer   = local.cognito_issuer
    audience = local.cognito_audience
  }
}

# Lambda integration — routes to alias when canary is enabled, otherwise to $LATEST
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.enable_canary_deployment ? aws_lambda_alias.canary[0].invoke_arn : aws_lambda_function.this.invoke_arn
  payload_format_version = "2.0"
}

# Route: POST /mcp — primary JSON-RPC endpoint
resource "aws_apigatewayv2_route" "post_mcp" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /mcp"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type   = var.enable_auth ? "JWT" : "NONE"
  authorizer_id        = var.enable_auth ? aws_apigatewayv2_authorizer.cognito[0].id : null
  authorization_scopes = var.enable_auth ? ["mcp/invoke"] : null
}

# Route: GET /mcp — SSE streaming endpoint
# NOTE: HTTP API v2 enforces a 30-second integration timeout on all routes.
# Long-lived SSE connections will be forcibly closed at 30 seconds.
# For long-polling, consider: (1) chunked-response pattern with reconnection,
# (2) REST API with response streaming, or (3) Lambda Function URLs with
# RESPONSE_STREAM invoke mode (incompatible with tenant isolation).
resource "aws_apigatewayv2_route" "get_mcp" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /mcp"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type   = var.enable_auth ? "JWT" : "NONE"
  authorizer_id        = var.enable_auth ? aws_apigatewayv2_authorizer.cognito[0].id : null
  authorization_scopes = var.enable_auth ? ["mcp/invoke"] : null
}

# Route: DELETE /mcp — session termination endpoint
resource "aws_apigatewayv2_route" "delete_mcp" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /mcp"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type   = var.enable_auth ? "JWT" : "NONE"
  authorizer_id        = var.enable_auth ? aws_apigatewayv2_authorizer.cognito[0].id : null
  authorization_scopes = var.enable_auth ? ["mcp/invoke"] : null
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  qualifier     = var.enable_canary_deployment ? aws_lambda_alias.canary[0].name : null
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*/mcp"
}

# ---------------------------------------------------------------------------
# WAF — NOT supported on HTTP API v2
# ---------------------------------------------------------------------------
# AWS WAFv2 cannot be directly associated with HTTP API v2 stages.
# For Layer 7 protection (FedRAMP SC-7), place a CloudFront distribution
# in front of the HTTP API and associate the WAFv2 Web ACL with CloudFront.
# See: docs/architecture/api-gateway.md — Known Limitations
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# ECR Repository (conditional)
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  count = var.enable_ecr_repository ? 1 : 0

  name                 = "${local.name_prefix}-mcp"
  image_tag_mutability = var.ecr_image_tag_mutability

  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.enable_ecr_repository ? 1 : 0

  repository = aws_ecr_repository.this[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# DynamoDB Sessions Table (conditional)
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "sessions" {
  count = var.enable_session_table ? 1 : 0

  name         = "${local.name_prefix}-mcp-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.enable_tenant_isolation ? "tenant_id" : "session_id"
  range_key    = var.enable_tenant_isolation ? "session_id" : null

  attribute {
    name = "session_id"
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.enable_tenant_isolation ? [1] : []
    content {
      name = "tenant_id"
      type = "S"
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.enable_tenant_isolation ? [1] : []
    content {
      name            = "session-id-index"
      hash_key        = "session_id"
      projection_type = "ALL"
    }
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # Global table replicas for multi-region failover (FedRAMP CP-7)
  dynamic "replica" {
    for_each = var.enable_global_table ? var.replica_regions : []
    content {
      region_name    = replica.value
      kms_key_arn    = lookup(var.replica_kms_key_arns, replica.value, null)
      propagate_tags = true
    }
  }

  deletion_protection_enabled = var.environment == "prod"

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# ECR Cross-Region Replication (conditional, FedRAMP CP-7)
# ---------------------------------------------------------------------------

resource "aws_ecr_replication_configuration" "this" {
  count = var.enable_ecr_replication && var.enable_ecr_repository ? 1 : 0

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.ecr_replication_regions
        content {
          region      = destination.value
          registry_id = data.aws_caller_identity.current.account_id
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Route53 Health Check (conditional, FedRAMP CP-7)
# ---------------------------------------------------------------------------

resource "aws_route53_health_check" "api" {
  count = var.enable_health_check ? 1 : 0

  fqdn              = replace(replace(aws_apigatewayv2_api.this.api_endpoint, "https://", ""), "/", "")
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = var.health_check_failure_threshold
  request_interval  = 30
  measure_latency   = true

  tags = merge(local.tags, {
    Name    = "${local.name_prefix}-mcp-health-check"
    FedRAMP = "CP-7"
  })
}

resource "aws_cloudwatch_metric_alarm" "health_check" {
  count = var.enable_health_check ? 1 : 0

  alarm_name          = "${local.name_prefix}-mcp-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Route53 health check failed for MCP API endpoint (FedRAMP CP-7)"
  treat_missing_data  = "breaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    HealthCheckId = aws_route53_health_check.api[0].id
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "CP-7" })
}

# ---------------------------------------------------------------------------
# Monitoring — SNS and CloudWatch Alarms (SI-4, IR-4)
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "alarms" {
  count = var.alarm_sns_topic_arn == null ? 1 : 0

  name              = "${local.name_prefix}-mcp-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = local.tags
}

# Lambda error rate alarm (SI-4)
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-mcp-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda function error rate exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# Lambda duration p99 alarm (SI-4)
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.name_prefix}-mcp-lambda-duration-p99"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p99"
  threshold           = var.timeout * 1000 * 0.8
  alarm_description   = "Lambda p99 duration approaching timeout (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# Lambda throttle alarm (SI-4, CM-7)
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${local.name_prefix}-mcp-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda function throttling detected (FedRAMP SI-4, CM-7)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# API Gateway 5xx errors alarm (SI-4)
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.name_prefix}-mcp-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway 5xx error rate exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    ApiId = aws_apigatewayv2_api.this.id
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# API Gateway 4xx errors alarm (SI-4)
resource "aws_cloudwatch_metric_alarm" "api_4xx" {
  alarm_name          = "${local.name_prefix}-mcp-api-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "API Gateway 4xx error rate exceeded threshold (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    ApiId = aws_apigatewayv2_api.this.id
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# API Gateway latency p99 alarm (SI-4)
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${local.name_prefix}-mcp-api-latency-p99"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  extended_statistic  = "p99"
  threshold           = var.timeout * 1000 * 0.9
  alarm_description   = "API Gateway p99 latency approaching timeout (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    ApiId = aws_apigatewayv2_api.this.id
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# Lambda ConcurrentExecutions alarm (SI-4)
resource "aws_cloudwatch_metric_alarm" "lambda_concurrent" {
  alarm_name          = "${local.name_prefix}-mcp-lambda-concurrent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.reserved_concurrent_executions > 0 ? var.reserved_concurrent_executions * 0.8 : 900
  alarm_description   = "Lambda concurrent executions approaching limit (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# DynamoDB ThrottledRequests alarm (SI-4)
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  count = var.enable_session_table ? 1 : 0

  alarm_name          = "${local.name_prefix}-mcp-dynamodb-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "DynamoDB table throttling detected (FedRAMP SI-4)"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    TableName = aws_dynamodb_table.sessions[0].name
  }

  alarm_actions = compact([local.alarm_sns_topic_arn])
  ok_actions    = compact([local.alarm_sns_topic_arn])

  tags = merge(local.tags, { FedRAMP = "SI-4" })
}

# ---------------------------------------------------------------------------
# SNS Email Subscription (IR-4)
# ---------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_notification_email != null && var.alarm_sns_topic_arn == null ? 1 : 0

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_notification_email
}

# ---------------------------------------------------------------------------
# Production Safety Check (IA-2)
# ---------------------------------------------------------------------------

check "auth_enabled_in_prod" {
  assert {
    condition     = !(var.environment == "prod" && !var.enable_auth)
    error_message = "WARNING: Authentication is disabled in production. This violates FedRAMP IA-2."
  }
}

check "cmk_in_prod" {
  assert {
    condition     = !(var.environment == "prod" && var.kms_key_arn == null)
    error_message = "WARNING: Using AWS-managed encryption in production. Consider a customer-managed KMS key for FedRAMP SC-12/SC-13 compliance."
  }
}
