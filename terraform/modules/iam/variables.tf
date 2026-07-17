variable "name_prefix" {
  description = "Prefix for the role & policy names."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to the role."
  type        = map(string)
}

variable "dynamodb_resource_arns" {
  description = "List of DynamoDB table/index ARNs this role may access. Passed in from the environment."
  type        = list(string)
}