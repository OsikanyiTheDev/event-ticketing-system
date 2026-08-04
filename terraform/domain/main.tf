###############################################################################
# terraform/domain — the SHARED platform layer.
# Route 53 zone + ACM cert + SES domain identity. Persists across app
# destroy/apply cycles. Has its OWN state (domain/terraform.tfstate) so it's
# never torn down with the app.
#
# The ONE manual step that stays outside Terraform:
#   pointing Namecheap's nameservers at the Route 53 zone's NS records.
#   (You can't automate an external registrar.) Everything else is code.
###############################################################################

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "osikanyithedev-terraform-state-2026"
    key          = "domain/terraform.tfstate" # separate state from the app
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

# CloudFront needs ACM certs in us-east-1, so this layer runs in us-east-1.
provider "aws" {
  region = "us-east-1"
}

variable "domain_name" {
  description = "Apex domain you own."
  type        = string
  default     = "osikanyi.online"
}

variable "app_subdomain" {
  description = "Subdomain for this project (used on the ACM cert + CloudFront)."
  type        = string
  default     = "ticketservice.osikanyi.online"
}

variable "common_tags" {
  description = "Tags applied to all domain resources."
  type        = map(string)
  default = {
    Project   = "osikanyi.online"
    ManagedBy = "Terraform domain layer"
  }
}

# ─────────────────────── Route 53 zone ───────────────────────
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.common_tags
}

# ─────────────────────── ACM certificate (us-east-1) ───────────────────────
resource "aws_acm_certificate" "app" {
  domain_name       = var.app_subdomain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

# DNS validation record (auto-added to the zone above)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Wait for the cert to be issued
resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ─────────────────────── SES domain identity + DKIM ───────────────────────
resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# SES domain verification TXT record
resource "aws_route53_record" "ses_verification" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = "_amazonses.${var.domain_name}"
  type            = "TXT"
  ttl             = 600
  records         = [aws_ses_domain_identity.main.verification_token]
  allow_overwrite = true
}

# 3 DKIM CNAME records
resource "aws_route53_record" "ses_dkim" {
  count           = 3
  zone_id         = aws_route53_zone.main.zone_id
  name            = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type            = "CNAME"
  ttl             = 600
  records         = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
  allow_overwrite = true
}

# ─────────────────────── SPF + DMARC (full email authentication) ───────────────────────
# DKIM alone is good; adding SPF + DMARC makes the domain fully authenticated,
# which strengthens any SES production-access request.
variable "notification_email" {
  description = "Email for DMARC aggregate reports (rua)."
  type        = string
  default     = "osikanyie@gmail.com"
}

# SPF — authorizes SES to send on this domain's behalf
resource "aws_route53_record" "spf" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = var.domain_name
  type            = "TXT"
  ttl             = 600
  records         = ["v=spf1 include:amazonses.com ~all"]
  allow_overwrite = true
}

# DMARC — monitor mode (p=none) is the recommended starting policy
resource "aws_route53_record" "dmarc" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = "_dmarc.${var.domain_name}"
  type            = "TXT"
  ttl             = 600
  records         = ["v=DMARC1; p=none; rua=mailto:${var.notification_email}"]
  allow_overwrite = true
}

# ─────────────────────── GitHub OIDC (for CD, no long-lived keys) ───────────────────────
variable "github_repo" {
  description = "GitHub repo (org/name) allowed to assume the deploy role."
  type        = string
  default     = "OsikanyiTheDev/event-ticketing-system"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub's OIDC thumbprint
}

resource "aws_iam_role" "github_deploy" {
  name = "github-actions-deploy"
  # Trust: only this repo's workflows can assume the role via OIDC
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

# NOTE: AdministratorAccess keeps CD simple. A scoped policy is the production
# hardening (Terraform needs broad perms to manage all resource types).
resource "aws_iam_role_policy_attachment" "github_deploy" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
