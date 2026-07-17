variable "project_name" {
  description = "Short prefix for resources (lowercase, digits, hyphens)."
  type        = string
  default     = "event-ticketing"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must be 3-20 chars: lowercase letters, digits, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable DynamoDB PITR. Off by default for Free Tier."
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Extra tags merged into the common set."
  type        = map(string)
  default     = {}
}