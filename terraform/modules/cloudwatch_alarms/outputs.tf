output "alarm_topic_arn" {
  description = "ARN of the alarm-notification SNS topic."
  value       = aws_sns_topic.alarms.arn
}
