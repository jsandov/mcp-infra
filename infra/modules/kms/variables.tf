variable "alias_name" {
  description = "Alias name for the KMS key (will be prefixed with environment)"
  type        = string

  validation {
    condition     = length(var.alias_name) >= 1 && length(var.alias_name) <= 50
    error_message = "Alias name must be between 1 and 50 characters."
  }
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "Customer-managed encryption key"
}

variable "environment" {
  description = "Environment name used for tagging (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "deletion_window_in_days" {
  description = "Number of days before the key is permanently deleted after scheduling deletion"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "admin_principal_arns" {
  description = "List of IAM principal ARNs allowed to administer the key"
  type        = list(string)
  default     = []
}

variable "usage_principal_arns" {
  description = "List of IAM principal ARNs allowed to use the key for encrypt/decrypt"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_logs_access" {
  description = "Whether to allow CloudWatch Logs service to use this key for log encryption"
  type        = bool
  default     = false
}

variable "enable_s3_access" {
  description = "Whether to allow S3 service to use this key for bucket encryption"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
