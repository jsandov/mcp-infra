variable "name" {
  description = "Name for the API Gateway (will be prefixed with environment)"
  type        = string
  default     = "api"

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 40
    error_message = "Name must be between 1 and 40 characters."
  }
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name used for tagging (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# -----------------------------------------------------------------------------
# Stage and Deployment
# -----------------------------------------------------------------------------

variable "enable_auto_deploy" {
  description = "Whether changes are automatically deployed to the default stage"
  type        = bool
  default     = true
}

variable "throttling_rate_limit" {
  description = "Requests per second rate limit for the default stage"
  type        = number
  default     = 1000

  validation {
    condition     = var.throttling_rate_limit >= 1 && var.throttling_rate_limit <= 10000
    error_message = "Throttling rate limit must be between 1 and 10000 requests per second."
  }
}

variable "throttling_burst_limit" {
  description = "Burst capacity for the default stage"
  type        = number
  default     = 500

  validation {
    condition     = var.throttling_burst_limit >= 1 && var.throttling_burst_limit <= 5000
    error_message = "Throttling burst limit must be between 1 and 5000."
  }
}

# -----------------------------------------------------------------------------
# Access Logging (FedRAMP AU-2, AU-3, AU-9)
# -----------------------------------------------------------------------------

variable "enable_access_logging" {
  description = "Whether to enable CloudWatch access logging for the API"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain API access logs in CloudWatch"
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention value."
  }
}

variable "kms_key_arn" {
  description = "ARN of a KMS key for encrypting CloudWatch Logs. If null, uses AWS-managed encryption."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

variable "enable_cors" {
  description = "Whether to enable CORS on the API"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = []
}

variable "cors_allowed_methods" {
  description = "List of allowed HTTP methods for CORS"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS"
  type        = list(string)
  default     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
}

variable "cors_expose_headers" {
  description = "List of headers to expose in CORS responses"
  type        = list(string)
  default     = []
}

variable "cors_max_age" {
  description = "Maximum age in seconds for CORS preflight cache"
  type        = number
  default     = 86400
}

variable "cors_allow_credentials" {
  description = "Whether to allow credentials in CORS requests"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# VPC Link (FedRAMP SC-7 — boundary protection)
# -----------------------------------------------------------------------------

variable "vpc_link_subnet_ids" {
  description = "List of subnet IDs for the VPC Link. If empty, no VPC Link is created."
  type        = list(string)
  default     = []
}

variable "vpc_link_security_group_ids" {
  description = "List of security group IDs for the VPC Link"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# WAF (FedRAMP SC-7 — Layer 7 protection)
# -----------------------------------------------------------------------------

variable "waf_acl_arn" {
  description = "ARN of the WAFv2 web ACL to associate with the API stage. If null, no WAF is attached."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
