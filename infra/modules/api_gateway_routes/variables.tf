# ---------------------------------------------------------------------------
# API Gateway Routes Module — variables.tf
# Per-service route isolation for shared API Gateway
# ---------------------------------------------------------------------------

variable "api_id" {
  description = "ID of the shared API Gateway v2 HTTP API to attach routes to."
  type        = string

  validation {
    condition     = length(var.api_id) > 0
    error_message = "api_id must not be empty."
  }
}

variable "api_execution_arn" {
  description = "Execution ARN of the shared API Gateway, used to scope the Lambda invoke permission."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:execute-api:", var.api_execution_arn))
    error_message = "api_execution_arn must be a valid API Gateway execution ARN (arn:aws:execute-api:...)."
  }
}

variable "service_name" {
  description = "Unique name identifying this service. Used in Lambda permission statement IDs to prevent collisions when multiple services share the same API Gateway."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service_name))
    error_message = "service_name must contain only lowercase letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.service_name) >= 1 && length(var.service_name) <= 40
    error_message = "service_name must be between 1 and 40 characters."
  }
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to integrate with routes."
  type        = string

  validation {
    condition     = length(var.lambda_function_name) >= 1 && length(var.lambda_function_name) <= 64
    error_message = "lambda_function_name must be between 1 and 64 characters."
  }
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for the API Gateway integration (from aws_lambda_function.invoke_arn)."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:apigateway:", var.lambda_invoke_arn))
    error_message = "lambda_invoke_arn must be a valid API Gateway invoke ARN (arn:aws:apigateway:...)."
  }
}

variable "routes" {
  description = "Map of route key to route configuration. Keys are API Gateway route keys (e.g., 'POST /mcp', 'GET /health'). Each service team defines only their own routes."
  type = map(object({
    authorization_type   = optional(string, "NONE")
    authorizer_id        = optional(string)
    authorization_scopes = optional(list(string))
  }))

  validation {
    condition     = length(var.routes) > 0
    error_message = "At least one route must be defined."
  }

  validation {
    condition = alltrue([
      for key, _ in var.routes : can(regex("^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS|ANY) /.+$", key))
    ])
    error_message = "Each route key must be in the format 'METHOD /path' (e.g., 'POST /mcp', 'GET /health')."
  }
}

variable "payload_format_version" {
  description = "Payload format version for the Lambda integration."
  type        = string
  default     = "2.0"

  validation {
    condition     = contains(["1.0", "2.0"], var.payload_format_version)
    error_message = "payload_format_version must be '1.0' or '2.0'."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources that support tagging."
  type        = map(string)
  default     = {}
}
