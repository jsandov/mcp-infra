# ---------------------------------------------------------------------------
# MCP Tenant Metering Module — variables.tf
# ---------------------------------------------------------------------------

variable "name" {
  description = "Name identifier for metering resources. Used as part of resource naming prefix."
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
  description = "Deployment environment (dev, staging, or prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources. Merged with default tags (Name, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting DynamoDB table, SNS topic, and CloudWatch resources."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS ARN starting with 'arn:aws:kms:'."
  }
}

variable "lambda_role_name" {
  description = "Name of the MCP server Lambda execution role. Used to attach an inline policy granting DynamoDB access."
  type        = string

  validation {
    condition     = length(var.lambda_role_name) >= 1
    error_message = "Lambda role name must not be empty."
  }
}

variable "api_log_group_name" {
  description = "CloudWatch log group name for API Gateway access logs. Required for metric filters and alarms. If null, only the DynamoDB usage table is created."
  type        = string
  default     = null
}

variable "metric_namespace" {
  description = "CloudWatch custom metric namespace for tenant metering metrics."
  type        = string
  default     = "MCP/TenantMetering"

  validation {
    condition     = length(var.metric_namespace) >= 1 && length(var.metric_namespace) <= 256
    error_message = "Metric namespace must be between 1 and 256 characters."
  }
}

variable "usage_ttl_days" {
  description = "Number of days to retain usage records in DynamoDB before automatic deletion via TTL."
  type        = number
  default     = 90

  validation {
    condition     = var.usage_ttl_days >= 1
    error_message = "Usage TTL must be at least 1 day."
  }
}

variable "enable_quota_alarm" {
  description = "Enable CloudWatch alarms for request quota and error rate thresholds."
  type        = bool
  default     = true
}

variable "quota_request_threshold" {
  description = "Request count threshold per alarm period. An alarm triggers when total requests exceed this value."
  type        = number
  default     = 10000

  validation {
    condition     = var.quota_request_threshold >= 1
    error_message = "Quota request threshold must be at least 1."
  }
}

variable "quota_alarm_period" {
  description = "Alarm evaluation period in seconds. Must be a valid CloudWatch period (60, 300, 3600, 86400, etc.)."
  type        = number
  default     = 86400

  validation {
    condition     = contains([10, 30, 60, 300, 900, 3600, 21600, 86400], var.quota_alarm_period)
    error_message = "Quota alarm period must be a valid CloudWatch period: 10, 30, 60, 300, 900, 3600, 21600, or 86400 seconds."
  }
}

variable "quota_alarm_evaluation_periods" {
  description = "Number of consecutive periods over which the quota threshold must be breached to trigger the alarm."
  type        = number
  default     = 1

  validation {
    condition     = var.quota_alarm_evaluation_periods >= 1
    error_message = "Quota alarm evaluation periods must be at least 1."
  }
}

variable "error_rate_threshold" {
  description = "Error count threshold per 5-minute period. An alarm triggers when 5xx errors exceed this value."
  type        = number
  default     = 50

  validation {
    condition     = var.error_rate_threshold >= 1
    error_message = "Error rate threshold must be at least 1."
  }
}

variable "alarm_sns_topic_arn" {
  description = "ARN of an existing SNS topic for metering alarm notifications. If null, a new topic is created."
  type        = string
  default     = null

  validation {
    condition     = var.alarm_sns_topic_arn == null || can(regex("^arn:aws:sns:", var.alarm_sns_topic_arn))
    error_message = "Alarm SNS topic ARN must be a valid AWS SNS ARN starting with 'arn:aws:sns:' or null."
  }
}
