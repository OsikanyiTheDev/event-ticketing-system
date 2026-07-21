###############################################################################
# modules/budgets/variables.tf
###############################################################################

variable "name_prefix" {
  description = "Prefix for the budget name."
  type        = string
}

variable "budget_amount" {
  description = "Monthly spend cap in USD. Keep low to stay in Free Tier."
  type        = string
  default     = "5.00"
}

variable "notification_email" {
  description = "Email address that receives budget alerts."
  type        = string
}
