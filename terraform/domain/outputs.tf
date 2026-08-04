###############################################################################
# terraform/domain/outputs.tf
###############################################################################

output "zone_id" {
  description = "Route 53 hosted zone ID for osikanyi.online."
  value       = aws_route53_zone.main.zone_id
}

output "nameservers" {
  description = "The 4 NS records to set at Namecheap (one-time, manual)."
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ARN of the ACM cert for the app subdomain."
  value       = aws_acm_certificate.app.arn
}

output "ses_domain" {
  description = "The verified SES domain."
  value       = aws_ses_domain_identity.main.domain
}

output "ses_identity_arn" {
  description = "ARN of the SES domain identity (for the app's IAM policy)."
  value       = aws_ses_domain_identity.main.arn
}

output "github_deploy_role_arn" {
  description = "ARN of the OIDC role GitHub Actions assumes for CD."
  value       = aws_iam_role.github_deploy.arn
}
