variable "topic_name" {
  description = "Name of the SNS topic."
  type        = string
}

variable "display_name" {
  description = "Human-friendly name shown in notification emails."
  type        = string
}

variable "subscriber_email" {
  description = "Email address that receives registration confirmations. Must be confirmed once via the AWS confirmation email."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.subscriber_email))
    error_message = "subscriber_email must be a valid email address."
  }
}

variable "common_tags" {
  description = "Tags applied to the topic."
  type        = map(string)
  default     = {}
}
