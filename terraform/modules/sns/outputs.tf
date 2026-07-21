output "topic_arn" {
  description = "ARN of the SNS topic (passed to the Lambda + IAM policy)."
  value       = aws_sns_topic.this.arn
}
