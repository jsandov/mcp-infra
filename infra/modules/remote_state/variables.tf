variable "bucket_name" {
  description = "Name of the S3 bucket for storing Terraform state"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "S3 bucket name must be between 3 and 63 characters."
  }
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "environment" {
  description = "Environment name used for tagging (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days before noncurrent state file versions are deleted"
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1
    error_message = "Expiration days must be at least 1."
  }
}

variable "kms_key_arn" {
  description = "ARN of a customer-managed KMS key for S3 encryption. If null, uses AES-256."
  type        = string
  default     = null
}

variable "allowed_principal_arns" {
  description = "List of IAM principal ARNs allowed to access the state bucket. If empty, no principal restriction is applied."
  type        = list(string)
  default     = []
}

variable "access_logs_bucket" {
  description = "S3 bucket name for state bucket access logging. If null, access logging is disabled."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 key prefix for access logs"
  type        = string
  default     = "state-access-logs"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
