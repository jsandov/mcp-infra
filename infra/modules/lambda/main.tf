# -----------------------------------------------------------------------------
# Lambda Module - Main Configuration
# FedRAMP-compliant AWS Lambda function with KMS encryption, least-privilege
# IAM, CloudWatch logging, and optional VPC/X-Ray/DLQ support.
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Name        = var.function_name
    Environment = var.environment
    ManagedBy   = "opentofu"
  }

  tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# IAM Execution Role
# -----------------------------------------------------------------------------

# Least-privilege execution role for the Lambda function (AC-6)
resource "aws_iam_role" "this" {
  name = "${var.function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# -----------------------------------------------------------------------------
# IAM Policy Attachments
# -----------------------------------------------------------------------------

# Basic execution role for CloudWatch Logs access (AU-2)
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access execution role - only when deploying into a VPC (SC-7)
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = length(var.vpc_subnet_ids) > 0 ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# X-Ray tracing write access - only when X-Ray tracing is enabled (SI-4)
resource "aws_iam_role_policy_attachment" "xray" {
  count = var.enable_xray_tracing ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------

# Encrypted CloudWatch log group with configurable retention (AU-2, SC-28)
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.this.arn

  # Deployment package - zip file, S3, or container image
  filename         = var.filename
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  image_uri        = var.image_uri
  package_type     = var.image_uri != null ? "Image" : "Zip"
  source_code_hash = var.filename != null ? filebase64sha256(var.filename) : null

  # Runtime configuration (not applicable for container images)
  runtime = var.image_uri != null ? null : var.runtime
  handler = var.image_uri != null ? null : var.handler

  # Resource allocation
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = var.architectures
  publish       = var.publish

  # Concurrency control
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # KMS encryption for environment variables at rest (SC-28)
  kms_key_arn = var.kms_key_arn

  # Environment variables (conditional)
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration for private Lambda deployment (SC-7)
  dynamic "vpc_config" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  # X-Ray distributed tracing (SI-4)
  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  # Dead letter queue for failed async invocations
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []

    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  # Ensure the log group is created before the function to avoid race conditions
  depends_on = [aws_cloudwatch_log_group.this]

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Lambda Alias with Canary Routing (conditional)
# When enabled, creates a named alias that can shift traffic between two
# Lambda versions for blue/green or canary deployments. Requires publish = true.
# -----------------------------------------------------------------------------

resource "aws_lambda_alias" "this" {
  count = var.enable_alias ? 1 : 0

  name             = var.alias_name
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

# -----------------------------------------------------------------------------
# Lambda Function URL (conditional)
# -----------------------------------------------------------------------------

resource "aws_lambda_function_url" "this" {
  count = var.enable_function_url ? 1 : 0

  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type
}
