output "api_id" {
  description = "ID of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "api_url" {
  description = "Base URL of the deployed API, e.g. https://abc123.execute-api.us-east-1.amazonaws.com/dev"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_name" {
  description = "Name of the deployed stage."
  value       = aws_api_gateway_stage.this.stage_name
}
