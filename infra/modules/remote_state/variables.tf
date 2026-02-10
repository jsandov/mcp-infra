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

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
