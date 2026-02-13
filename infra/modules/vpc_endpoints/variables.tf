variable "vpc_id" {
  description = "The ID of the VPC to create endpoints in"
  type        = string
}

variable "environment" {
  description = "Environment name used for tagging (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "route_table_ids" {
  description = "List of route table IDs to associate with Gateway endpoints"
  type        = list(string)

  validation {
    condition     = length(var.route_table_ids) > 0
    error_message = "At least one route table ID must be provided."
  }
}

variable "enable_s3_endpoint" {
  description = "Whether to create an S3 Gateway VPC Endpoint"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Whether to create a DynamoDB Gateway VPC Endpoint"
  type        = bool
  default     = true
}

variable "s3_endpoint_policy" {
  description = "IAM policy document for the S3 endpoint. If null, allows full S3 access within the VPC."
  type        = string
  default     = null
}

variable "dynamodb_endpoint_policy" {
  description = "IAM policy document for the DynamoDB endpoint. If null, allows full DynamoDB access within the VPC."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for Interface VPC Endpoints"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for Interface VPC Endpoints"
  type        = list(string)
  default     = []
}

variable "enable_sts_endpoint" {
  description = "Whether to create an STS Interface VPC Endpoint (required for Lambda VPC + STS AssumeRole)"
  type        = bool
  default     = false
}

variable "enable_kms_endpoint" {
  description = "Whether to create a KMS Interface VPC Endpoint (required for Lambda VPC + KMS encryption)"
  type        = bool
  default     = false
}

variable "enable_logs_endpoint" {
  description = "Whether to create a CloudWatch Logs Interface VPC Endpoint"
  type        = bool
  default     = false
}

variable "enable_ecr_api_endpoint" {
  description = "Whether to create an ECR API Interface VPC Endpoint (required for container image pulls without NAT)"
  type        = bool
  default     = false
}

variable "enable_ecr_dkr_endpoint" {
  description = "Whether to create an ECR Docker Interface VPC Endpoint (required for container image pulls without NAT)"
  type        = bool
  default     = false
}

variable "enable_xray_endpoint" {
  description = "Whether to create an X-Ray Interface VPC Endpoint"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
