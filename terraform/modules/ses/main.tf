###############################################################################
# modules/ses/main.tf
# SES email identity used as the FROM address for transactional confirmations.
#
# WHY SES (not SNS) for the registrant: SNS sends to FIXED subscribers and
# can't email an arbitrary registrant. SES sends transactional email to ANY
# address (the registrant's). So:
#   • SNS  → admin notification (fixed subscriber)
#   • SES  → confirmation to the person who registered (dynamic recipient)
#
# SANDBOX NOTE: new SES accounts are in "sandbox" mode — BOTH the sender AND
# the recipient must be verified identities. For the demo, register with a
# verified email. To email anyone, request production access in the SES console.
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_ses_email_identity" "sender" {
  email = var.sender_email
}
