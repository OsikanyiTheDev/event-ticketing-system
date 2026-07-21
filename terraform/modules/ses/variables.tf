###############################################################################
# modules/ses/variables.tf
###############################################################################

variable "sender_email" {
  description = "Email address verified as the SES FROM address. Must be confirmed via the AWS verification email."
  type        = string
}
