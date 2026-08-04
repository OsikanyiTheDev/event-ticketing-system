###############################################################################
# modules/cloudfront/outputs.tf
###############################################################################

output "distribution_domain_name" {
  description = "CloudFront domain (dXXXX.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "website_url" {
  description = "The public HTTPS custom-domain URL."
  value       = "https://${var.domain_name}"
}
