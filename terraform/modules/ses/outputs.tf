###############################################################################
# modules/ses/outputs.tf
###############################################################################

output "identity_arn" {
  description = "ARN of the SES email identity — passed to the IAM policy (least-privilege)."
  value       = aws_ses_email_identity.sender.arn
}

output "sender_email" {
  description = "The verified sender email."
  value       = aws_ses_email_identity.sender.email
}
