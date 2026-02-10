variable "function_name" {
  description = "Unique name for the Lambda function"
  type        = string

  validation {
    condition     = length(var.function_name) >= 1 && length(var.function_name) <= 64 && can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "Function name must be 1-64 characters and match ^[a-zA-Z0-9-_]+$."
  }
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Lambda runtime identifier (e.g., python3.12, nodejs20.x, java21, provided.al2023)"
  type        = string

  validation {
    condition     = can(regex("^(python3\\.[0-9]+|nodejs[0-9]+\\.x|java[0-9]+|dotnet[0-9]+|ruby[0-9]+\\.[0-9]+|go1\\.x|provided(\\.al2(023)?)?)$", var.runtime))
    error_message = "Runtime must be a valid Lambda runtime (e.g., python3.12, nodejs20.x, java21, provided.al2023)."
  }
}

variable "handler" {
  description = "Function entrypoint in the code (e.g., index.handler). Required for zip deployments, not for container images."
  type        = string
  default     = null
}

variable "timeout" {
  description = "Maximum execution time in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Amount of memory in MB available to the function at runtime"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "filename" {
  description = "Path to the local zip file containing the function code"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 object key of the deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR container image URI for container-based Lambda deployments"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt environment variables at rest (SC-28)"
  type        = string
  default     = null
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for VPC-connected Lambda execution (SC-7)"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for VPC-connected Lambda execution"
  type        = list(string)
  default     = []
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray active tracing for distributed tracing and performance monitoring (SI-4)"
  type        = bool
  default     = true
}

variable "reserved_concurrent_executions" {
  description = "Number of concurrent executions reserved for this function (-1 for unreserved)"
  type        = number
  default     = -1
}

variable "dead_letter_target_arn" {
  description = "ARN of an SNS topic or SQS queue for failed async invocation dead-letter delivery"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log events (AU-2)"
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention value (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653)."
  }
}

variable "log_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt CloudWatch log data at rest (SC-28)"
  type        = string
  default     = null
}

variable "enable_function_url" {
  description = "Enable a Lambda function URL for direct HTTPS invocation"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Authorization type for the function URL (AWS_IAM or NONE)"
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "Function URL auth type must be one of: AWS_IAM, NONE."
  }
}

variable "environment" {
  description = "Environment name used for tagging and resource naming (e.g., dev, staging, prod)"
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
