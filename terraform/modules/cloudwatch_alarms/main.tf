###############################################################################
# modules/cloudwatch_alarms/main.tf
# CloudWatch alarms + a dedicated alarm-notification SNS topic.
#
# The headline alarm: Lambda ERROR RATE > 5% (errors / invocations). Built with
# METRIC MATH — CloudWatch divides two metrics (Errors ÷ Invocations) on the fly
# so we get a true rate, not raw counts. We also alarm on Throttles.
#
# Each alarm publishes to its own SNS topic (separate from the confirmation
# topic) so alarm emails don't mix with registration emails.
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ───────────────────── Alarm notification topic ────────────────────
resource "aws_sns_topic" "alarms" {
  name         = "${var.name_prefix}-alarms"
  display_name = "${var.name_prefix} Alarms"
  tags         = var.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ───────────────────── Error-rate alarm (per function) ────────────────────
# metric math: errors / invocations, guarding divide-by-zero.
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  for_each = toset(var.function_names)

  alarm_name          = "${var.name_prefix}-${each.value}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.05 # 5%
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"
  alarm_description   = "Error rate for Lambda ${each.value} exceeds 5%"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  tags                = var.common_tags

  metric_query {
    id          = "error_rate"
    expression  = "IF(invocations > 0, errors / invocations, 0)"
    return_data = true
  }
  metric_query {
    id = "errors"
    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = "300"
      stat        = "Sum"
      dimensions = {
        FunctionName = each.value
      }
    }
  }
  metric_query {
    id = "invocations"
    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      period      = "300"
      stat        = "Sum"
      dimensions = {
        FunctionName = each.value
      }
    }
  }
}

# ───────────────────── Throttle alarm (per function) ────────────────────
# Any throttle is bad → threshold 0.
resource "aws_cloudwatch_metric_alarm" "throttles" {
  for_each = toset(var.function_names)

  alarm_name          = "${var.name_prefix}-${each.value}-throttles"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Lambda ${each.value} was throttled (concurrency limit hit)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  tags                = var.common_tags

  metric_name = "Throttles"
  namespace   = "AWS/Lambda"
  period      = "300"
  statistic   = "Sum"
  dimensions = {
    FunctionName = each.value
  }
}
