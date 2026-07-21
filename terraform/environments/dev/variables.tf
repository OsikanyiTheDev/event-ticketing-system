###############################################################################
# environments/dev/variables.tf
# Inputs for the dev environment.
###############################################################################

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
  description = "Deployment environment. Drives resource naming & tagging."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region. us-east-1 has the best Free Tier coverage."
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable DynamoDB Point-in-Time Recovery. Off by default for Free Tier."
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Extra tags merged into the common set (e.g. { Owner = \"name\" })."
  type        = map(string)
  default     = {}
}

variable "notification_email" {
  description = "Email address that receives registration confirmation messages. Must be confirmed once via the AWS email after apply."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly AWS spend cap in USD. Alerts fire at 50% actual and 100% forecasted."
  type        = string
  default     = "5.00"
}

variable "website_bucket_name" {
  description = "Globally-unique S3 bucket name for the static website."
  type        = string
  default     = "osikanyi-event-ticketing-ui"
}
