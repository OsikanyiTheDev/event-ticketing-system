###############################################################################
# environments/dev/outputs.tf
###############################################################################

output "events_table_name" {
  description = "Events table name."
  value       = module.dynamodb.events_table_name
}

output "registrations_table_name" {
  description = "Registrations table name."
  value       = module.dynamodb.registrations_table_name
}

output "registrations_gsi_name" {
  description = "Email GSI name on the Registrations table."
  value       = module.dynamodb.registrations_gsi_name
}

output "lambda_exec_role_arn" {
  description = "Lambda execution role ARN."
  value       = module.iam.lambda_exec_role_arn
}

output "list_events_function_name" {
  description = "Name of the GET /events Lambda."
  value       = module.lambda_list_events.function_name
}

output "register_function_name" {
  description = "Name of the POST /register Lambda."
  value       = module.lambda_register.function_name
}

output "get_registrations_function_name" {
  description = "Name of the GET /registrations Lambda."
  value       = module.lambda_get_registrations.function_name
}

output "cancel_registration_function_name" {
  description = "Name of the DELETE /registration Lambda."
  value       = module.lambda_cancel_registration.function_name
}

output "api_url" {
  description = "Public base URL of the REST API."
  value       = module.api_gateway.api_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS confirmation topic."
  value       = module.sns.topic_arn
}
