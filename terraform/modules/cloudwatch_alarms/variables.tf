variable "name_prefix" {
  description = "Prefix for alarm names."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to alarms + the alarm topic."
  type        = map(string)
  default     = {}
}

variable "function_names" {
  description = "Lambda function names to monitor (an alarm set is created per function)."
  type        = list(string)
}

variable "alarm_email" {
  description = "Email address that receives alarm notifications. Confirm once via AWS email after apply."
  type        = string
}
