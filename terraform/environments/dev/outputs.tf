output "events_table_name" {
  value = module.dynamodb.events_table_name
}
output "registrations_table_name" {
  value = module.dynamodb.registrations_table_name
}
output "registrations_gsi_name" {
  value = module.dynamodb.registrations_gsi_name
}
output "lambda_exec_role_arn" {
  value = module.iam.lambda_exec_role_arn
}
output "lambda_exec_role_name" {
  value = module.iam.lambda_exec_role_name
}