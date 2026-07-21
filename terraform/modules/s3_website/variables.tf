variable "bucket_name" {
  description = "Globally-unique S3 bucket name for the website."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default     = {}
}
