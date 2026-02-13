# =============================================================================
# Input Variables — API Gateway Platform
# =============================================================================

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# -----------------------------------------------------------------------------
# JWT Authorizer Configuration
# -----------------------------------------------------------------------------

variable "jwt_issuer" {
  description = "The JWT issuer URL, typically the Cognito user pool endpoint (e.g., https://cognito-idp.us-east-1.amazonaws.com/us-east-1_EXAMPLE)"
  type        = string

  validation {
    condition     = can(regex("^https://", var.jwt_issuer))
    error_message = "The jwt_issuer must be a valid HTTPS URL."
  }
}

variable "jwt_audience" {
  description = "List of JWT audience values, typically Cognito app client IDs that are allowed to access the API"
  type        = list(string)

  validation {
    condition     = length(var.jwt_audience) > 0
    error_message = "At least one JWT audience value (app client ID) is required."
  }
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS (e.g., ['https://app.example.com'])"
  type        = list(string)
  default     = ["https://app.example.com"]

  validation {
    condition     = length(var.cors_allowed_origins) > 0
    error_message = "At least one CORS allowed origin is required."
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources created by this stack"
  type        = map(string)
  default     = {}
}
