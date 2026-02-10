variable "vpc_id" {
  description = "The ID of the VPC to create security groups in"
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

variable "create_web_sg" {
  description = "Whether to create the web tier security group (HTTP/HTTPS)"
  type        = bool
  default     = true
}

variable "create_app_sg" {
  description = "Whether to create the application tier security group"
  type        = bool
  default     = true
}

variable "create_db_sg" {
  description = "Whether to create the database tier security group"
  type        = bool
  default     = true
}

variable "create_bastion_sg" {
  description = "Whether to create the bastion host security group"
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Port the application listens on (used for app tier ingress from web tier)"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "App port must be between 1 and 65535."
  }
}

variable "db_port" {
  description = "Port the database listens on (e.g., 5432 for PostgreSQL, 3306 for MySQL)"
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

variable "bastion_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion hosts"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.bastion_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All bastion allowed CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
