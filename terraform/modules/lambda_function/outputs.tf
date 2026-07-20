output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "qualified_arn" {
  description = "Qualified ARN (with version) — used by API Gateway integration."
  value       = aws_lambda_function.this.qualified_arn
}
output "invoke_arn" {
  description = "Invoke ARN for API Gateway integration."
  value       = aws_lambda_function.this.invoke_arn
}