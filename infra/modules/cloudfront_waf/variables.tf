# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for resources"
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 40 && can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must be 1-40 lowercase alphanumeric characters and hyphens."
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

# -----------------------------------------------------------------------------
# API Gateway Origin
# -----------------------------------------------------------------------------

variable "api_gateway_endpoint" {
  description = "The API Gateway endpoint URL (e.g., https://abc123.execute-api.us-east-1.amazonaws.com)"
  type        = string

  validation {
    condition     = can(regex("^https://", var.api_gateway_endpoint))
    error_message = "API Gateway endpoint must start with https://."
  }
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name appended to the origin path"
  type        = string
  default     = "$default"
}

# -----------------------------------------------------------------------------
# CloudFront
# -----------------------------------------------------------------------------

variable "price_class" {
  description = "CloudFront price class (PriceClass_100 = US/EU, PriceClass_200 = +Asia, PriceClass_All = global)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "custom_domain_name" {
  description = "Custom domain name for the CloudFront distribution (requires certificate_arn)"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the custom domain (must be in us-east-1 for CloudFront)"
  type        = string
  default     = null
}

variable "geo_restriction_type" {
  description = "CloudFront geo restriction type"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be one of: none, whitelist, blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1 alpha-2 country codes for geo restriction"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# WAF
# -----------------------------------------------------------------------------

variable "enable_waf" {
  description = "Whether to create and attach a WAFv2 Web ACL to the CloudFront distribution (FedRAMP SC-7)"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5-minute window per IP before rate-limiting (WAF rate-based rule)"
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit >= 100 && var.waf_rate_limit <= 2000000000
    error_message = "WAF rate limit must be between 100 and 2,000,000,000."
  }
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

variable "enable_logging" {
  description = "Enable CloudFront access logging to S3"
  type        = bool
  default     = false
}

variable "log_bucket_domain_name" {
  description = "S3 bucket domain name for CloudFront access logs (required when enable_logging is true)"
  type        = string
  default     = null
}

variable "log_prefix" {
  description = "S3 key prefix for CloudFront access logs"
  type        = string
  default     = "cloudfront/"
}

variable "kms_key_arn" {
  description = "ARN of a KMS key for WAF log group encryption"
  type        = string
  default     = null
}
