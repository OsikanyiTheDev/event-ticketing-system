###############################################################################
# modules/budgets/main.tf
# AWS Budgets — a monthly COST budget that emails you before you overspend.
#
# This is the Free-Tier safety net: if anything non-free starts charging, the
# 50% actual alert fires early (e.g. $2.50 of a $5 budget), and the 100%
# forecasted alert warns if you're trending over the cap.
#
# Budgets send notifications directly by EMAIL (no SNS policy needed), so this
# is the simplest, conflict-free cost control.
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_budgets_budget" "monthly" {
  name              = "${var.name_prefix}-monthly"
  budget_type       = "COST"
  limit_amount      = var.budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-07-01_00:00"

  # 1) Alert when ACTUAL spend crosses 50% of the budget (catch unexpected cost early)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }

  # 2) Alert when FORECASTED spend crosses 100% (trending over budget)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
  }
}
