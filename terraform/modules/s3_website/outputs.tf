output "bucket_name" {
  description = "Name of the website S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "website_endpoint" {
  description = "S3 website endpoint (the origin for CloudFront)."
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

output "website_url" {
  description = "Public URL of the static website (HTTP — add CloudFront for HTTPS)."
  value       = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}"
}
