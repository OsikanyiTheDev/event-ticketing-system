variable "api_name" {
  description = "Name of the REST API."
  type        = string
}

variable "stage_name" {
  description = "Deployment stage name (e.g. dev). Becomes the first URL segment."
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Tags applied to API Gateway resources."
  type        = map(string)
  default     = {}
}

variable "lambdas" {
  description = <<EOT
Map of logical route key -> Lambda details. Each value needs:
  invoke_arn    : the Lambda's API-Gateway invoke ARN (uri)
  function_name : the Lambda's name (for the invoke permission)
EOT
  type = map(object({
    invoke_arn    = string
    function_name = string
  }))
}
