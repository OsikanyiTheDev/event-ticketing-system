variable "name_prefix" {
  description = "Prefix for table names, e.g. 'event-ticketing-dev'."
  type        = string
}

variable "pitr_enabled" {
  description = "Enable Point-in-Time Recovery. Off by default for Free Tier."
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Tags applied to both tables (passed in from the environment)."
  type        = map(string)
}