###############################################################################
# modules/cloudfront/variables.tf
###############################################################################

variable "website_endpoint" {
  description = "S3 website endpoint serving the UI (origin)."
  type        = string
}

variable "domain_name" {
  description = "Custom domain (alternate name) for the distribution, e.g. ticketservice.osikanyi.online."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN (must be in us-east-1 for CloudFront)."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 zone ID where the alias record is created."
  type        = string
}

variable "comment" {
  description = "Distribution comment."
  type        = string
  default     = "Event Registration UI"
}

variable "price_class" {
  description = "Edge location price class. PriceClass_100 = North America + Europe (cheapest)."
  type        = string
  default     = "PriceClass_100"
}

variable "common_tags" {
  description = "Tags applied to the distribution."
  type        = map(string)
  default     = {}
}
