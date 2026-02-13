# ---------------------------------------------------------------------------
# MCP Server Module — variables.tf
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------

variable "name" {
  description = "Name identifier for the MCP server resources"
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 40
    error_message = "Name must be between 1 and 40 characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------

variable "image_uri" {
  description = "ECR image URI for the Lambda function container image"
  type        = string
}

variable "memory_size" {
  description = "Amount of memory in MB allocated to the Lambda function"
  type        = number
  default     = 512

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Maximum execution time in seconds for the Lambda function"
  type        = number
  default     = 180

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the Lambda function (-1 for unreserved)"
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Environment variables to pass to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "enable_tenant_isolation" {
  description = "Enable Lambda tenant isolation mode for per-tenant Firecracker VM isolation (FedRAMP SC-7). Immutable after creation. Incompatible with provisioned concurrency."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the Lambda function will run"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of private subnet IDs for the Lambda function VPC configuration"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for the Lambda function VPC configuration"
  type        = list(string)
}

# ---------------------------------------------------------------------------
# Encryption
# ---------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt environment variables, logs, and data at rest"
  type        = string
}

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

variable "enable_auth" {
  description = "Enable Cognito JWT authentication for the API Gateway (FedRAMP IA-2)"
  type        = bool
  default     = true
}

variable "cognito_user_pool_id" {
  description = "ID of an external Cognito user pool to use instead of creating a new one. When set, enable_auth must also be true."
  type        = string
  default     = null
}

variable "cognito_user_pool_endpoint" {
  description = "Endpoint of the external Cognito user pool (e.g., cognito-idp.us-east-1.amazonaws.com/us-east-1_xxx). Required when cognito_user_pool_id is set."
  type        = string
  default     = null
}

variable "cognito_client_id" {
  description = "Client ID from the external Cognito user pool. Required when cognito_user_pool_id is set."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 100

  validation {
    condition     = var.throttle_rate_limit >= 1 && var.throttle_rate_limit <= 10000
    error_message = "Throttle rate limit must be between 1 and 10000."
  }
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit (maximum concurrent requests)"
  type        = number
  default     = 50

  validation {
    condition     = var.throttle_burst_limit >= 1 && var.throttle_burst_limit <= 5000
    error_message = "Throttle burst limit must be between 1 and 5000."
  }
}

variable "cors_allowed_origins" {
  description = "List of allowed CORS origins for the API Gateway"
  type        = list(string)
  default     = ["*"]
}

variable "route_throttle_overrides" {
  description = "Per-route throttling overrides for API Gateway routes. Keys are route keys (e.g., 'POST /mcp')."
  type = map(object({
    throttling_rate_limit  = number
    throttling_burst_limit = number
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Session
# ---------------------------------------------------------------------------

variable "enable_session_table" {
  description = "Enable DynamoDB table for MCP session management"
  type        = bool
  default     = false
}

variable "session_ttl_seconds" {
  description = "TTL in seconds for session records in DynamoDB"
  type        = number
  default     = 3600

  validation {
    condition     = var.session_ttl_seconds >= 60
    error_message = "Session TTL must be at least 60 seconds."
  }
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------

variable "enable_ecr_repository" {
  description = "Enable creation of an ECR repository for the MCP server container image"
  type        = bool
  default     = false
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository (IMMUTABLE recommended for production)"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ECR image tag mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "ecr_scan_on_push" {
  description = "Enable image vulnerability scanning on push to ECR"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log events"
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.log_retention_days
    )
    error_message = "Log retention days must be a valid CloudWatch Logs retention value."
  }
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray active tracing for the Lambda function (FedRAMP SI-4)"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "ARN of an existing SNS topic for CloudWatch alarm notifications (creates a new topic if null)"
  type        = string
  default     = null
}

variable "alarm_actions_enabled" {
  description = "Enable alarm actions for CloudWatch metric alarms"
  type        = bool
  default     = true
}
