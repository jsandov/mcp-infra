# -----------------------------------------------------------------------------
# General Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for alarm resources"
  type        = string
  default     = "infra"
}

variable "environment" {
  description = "Environment name used for tagging and naming (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "kms_key_arn" {
  description = "ARN of a KMS key for SNS topic encryption. If null, SNS encryption is disabled."
  type        = string
  default     = null
}

variable "remediation_lambda_arn" {
  description = "ARN of an optional Lambda function for auto-remediation actions"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# ALB Variables
# -----------------------------------------------------------------------------

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (required when ALB alarms are enabled)"
  type        = string
  default     = ""
}

variable "alb_target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group (required when ALB unhealthy alarm is enabled)"
  type        = string
  default     = ""
}

# ALB 5xx Alarm

variable "enable_alb_5xx_alarm" {
  description = "Enable the ALB 5xx error rate alarm"
  type        = bool
  default     = false
}

variable "alb_5xx_threshold" {
  description = "Number of ALB 5xx errors to trigger the alarm"
  type        = number
  default     = 50
}

variable "alb_5xx_period" {
  description = "Period in seconds over which the ALB 5xx metric is evaluated"
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Number of evaluation periods before the ALB 5xx alarm triggers"
  type        = number
  default     = 3
}

# ALB Unhealthy Targets Alarm

variable "enable_alb_unhealthy_alarm" {
  description = "Enable the ALB unhealthy targets alarm"
  type        = bool
  default     = false
}

variable "alb_unhealthy_threshold" {
  description = "Number of unhealthy targets to trigger the alarm"
  type        = number
  default     = 0
}

variable "alb_unhealthy_period" {
  description = "Period in seconds over which the ALB unhealthy targets metric is evaluated"
  type        = number
  default     = 300
}

variable "alb_unhealthy_evaluation_periods" {
  description = "Number of evaluation periods before the ALB unhealthy targets alarm triggers"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# API Gateway Variables
# -----------------------------------------------------------------------------

variable "apigw_api_id" {
  description = "API Gateway API ID (required when API Gateway alarms are enabled)"
  type        = string
  default     = ""
}

# API Gateway 5xx Alarm

variable "enable_apigw_5xx_alarm" {
  description = "Enable the API Gateway 5xx error rate alarm"
  type        = bool
  default     = false
}

variable "apigw_5xx_threshold" {
  description = "Number of API Gateway 5xx errors to trigger the alarm"
  type        = number
  default     = 50
}

variable "apigw_5xx_period" {
  description = "Period in seconds over which the API Gateway 5xx metric is evaluated"
  type        = number
  default     = 300
}

variable "apigw_5xx_evaluation_periods" {
  description = "Number of evaluation periods before the API Gateway 5xx alarm triggers"
  type        = number
  default     = 3
}

# API Gateway 4xx Alarm

variable "enable_apigw_4xx_alarm" {
  description = "Enable the API Gateway 4xx error rate alarm"
  type        = bool
  default     = false
}

variable "apigw_4xx_threshold" {
  description = "Number of API Gateway 4xx errors to trigger the alarm"
  type        = number
  default     = 200
}

variable "apigw_4xx_period" {
  description = "Period in seconds over which the API Gateway 4xx metric is evaluated"
  type        = number
  default     = 300
}

variable "apigw_4xx_evaluation_periods" {
  description = "Number of evaluation periods before the API Gateway 4xx alarm triggers"
  type        = number
  default     = 3
}

# API Gateway Latency Alarm

variable "enable_apigw_latency_alarm" {
  description = "Enable the API Gateway latency alarm"
  type        = bool
  default     = false
}

variable "apigw_latency_threshold" {
  description = "API Gateway p99 latency threshold in milliseconds"
  type        = number
  default     = 5000
}

variable "apigw_latency_period" {
  description = "Period in seconds over which the API Gateway latency metric is evaluated"
  type        = number
  default     = 300
}

variable "apigw_latency_evaluation_periods" {
  description = "Number of evaluation periods before the API Gateway latency alarm triggers"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# VPC Flow Logs Variables
# -----------------------------------------------------------------------------

variable "vpc_flow_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs (required when VPC alarm is enabled)"
  type        = string
  default     = ""
}

variable "enable_vpc_rejected_alarm" {
  description = "Enable the VPC Flow Logs rejected packets alarm"
  type        = bool
  default     = false
}

variable "vpc_rejected_threshold" {
  description = "Number of rejected packets to trigger the alarm"
  type        = number
  default     = 1000
}

variable "vpc_rejected_period" {
  description = "Period in seconds over which the VPC rejected packets metric is evaluated"
  type        = number
  default     = 300
}

variable "vpc_rejected_evaluation_periods" {
  description = "Number of evaluation periods before the VPC rejected packets alarm triggers"
  type        = number
  default     = 3
}
