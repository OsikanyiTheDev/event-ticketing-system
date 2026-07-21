variable "name_prefix" {
  description = "Prefix for the role & policy names."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to the role."
  type        = map(string)
}

variable "dynamodb_resource_arns" {
  description = "List of DynamoDB table/index ARNs this role may access. Passed in from the environment so the module stays reusable and least-privilege."
  type        = list(string)
}

variable "sns_topic_arn" {
  description = "SNS topic ARN the role may publish to. Used only when enable_sns = true."
  type        = string
  default     = ""
}

variable "enable_sns" {
  description = "When true, grant the role sns:Publish on sns_topic_arn."
  type        = bool
  default     = false
}

variable "enable_ses" {
  description = "When true, grant the role ses:SendEmail on ses_identity_arn."
  type        = bool
  default     = false
}

variable "ses_identity_arn" {
  description = "ARN of the SES identity the role may send from. Used only when enable_ses = true."
  type        = string
  default     = ""
}
