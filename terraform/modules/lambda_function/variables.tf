variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "description" {
  description = "Description of the function."
  type        = string
  default     = ""
}

variable "handler_app_dir" {
  description = "Absolute path to the handler folder containing app.py."
  type        = string
}

variable "common_dir" {
  description = "Absolute path to the shared common/ library folder."
  type        = string
}

variable "handler" {
  description = "Lambda handler reference (file.function)."
  type        = string
  default     = "app.handler"
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "role_arn" {
  description = "ARN of the IAM execution role (created in Stage 1)."
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Memory in MB (also scales CPU)."
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables injected at runtime (table names, etc.)."
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Tags applied to the function."
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "How long to keep CloudWatch Logs. Lower = cheaper."
  type        = number
  default     = 14
}