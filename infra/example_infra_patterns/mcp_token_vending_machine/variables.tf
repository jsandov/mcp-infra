# ---------------------------------------------------------------------------
# MCP Token Vending Machine Module — variables.tf
# ---------------------------------------------------------------------------

variable "name" {
  description = "Name identifier for TVM resources. Used as part of the resource name prefix."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 40
    error_message = "Name must be between 1 and 40 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment for the TVM resources."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to all TVM resources. Merged with default tags (Name, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

variable "lambda_role_arn" {
  description = "ARN of the MCP server Lambda execution role. Used in the tenant role trust policy to allow the Lambda to assume tenant roles."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.lambda_role_arn))
    error_message = "lambda_role_arn must be a valid IAM role ARN (arn:aws:iam::<account-id>:role/<role-name>)."
  }
}

variable "lambda_role_name" {
  description = "Name of the MCP server Lambda execution role. Used for attaching the STS assume-role inline policy."
  type        = string

  validation {
    condition     = length(var.lambda_role_name) >= 1 && length(var.lambda_role_name) <= 64
    error_message = "lambda_role_name must be between 1 and 64 characters."
  }
}

variable "tenant_role_arn_pattern" {
  description = "ARN pattern for tenant roles that the Lambda is allowed to assume (e.g., arn:aws:iam::{AWS_ACCOUNT_ID}:role/mcp-tenant-*)."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.tenant_role_arn_pattern))
    error_message = "tenant_role_arn_pattern must be a valid IAM role ARN pattern (arn:aws:iam::<account-id>:role/<pattern>)."
  }
}

variable "allowed_actions" {
  description = "List of IAM actions allowed in the tenant permission boundary. These define the maximum permissions any tenant role can have. Actual tenant role policies should be narrower than this list."
  type        = list(string)

  default = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:ListBucket",
    "s3:DeleteObject",
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:UpdateItem",
    "dynamodb:DeleteItem",
    "dynamodb:Query",
    "dynamodb:Scan",
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret",
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:GenerateDataKey"
  ]

  validation {
    condition     = length(var.allowed_actions) > 0
    error_message = "At least one allowed action must be specified."
  }

  validation {
    condition     = alltrue([for action in var.allowed_actions : can(regex("^[a-zA-Z0-9]+:[a-zA-Z]+$", action))])
    error_message = "Each action must be a specific IAM action in the format 'service:Action' (e.g., 's3:GetObject'). Wildcard actions are not permitted."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption operations in the permission boundary. When provided, tenant roles are allowed to use this key for decrypt, describe, and generate data key operations."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.kms_key_arn))
    error_message = "kms_key_arn must be null or a valid KMS key ARN (arn:aws:kms:<region>:<account-id>:key/<key-id>)."
  }
}

variable "enable_template_role" {
  description = "Whether to create a template tenant IAM role. The template role demonstrates the correct configuration (trust policy, permission boundary, session duration) for per-tenant roles."
  type        = bool
  default     = true
}

variable "tenant_session_duration" {
  description = "Maximum session duration in seconds for tenant roles. Determines how long STS credentials remain valid. Minimum 900 (15 min), maximum 43200 (12 hours)."
  type        = number
  default     = 3600

  validation {
    condition     = var.tenant_session_duration >= 900 && var.tenant_session_duration <= 43200
    error_message = "tenant_session_duration must be between 900 (15 minutes) and 43200 (12 hours) seconds."
  }
}
