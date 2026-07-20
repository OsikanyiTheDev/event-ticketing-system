# This file wires modules together. It defines NO resources of its own.

module "dynamodb" {
  source       = "../../modules/dynamodb"
  name_prefix  = local.name_prefix
  common_tags  = local.common_tags
  pitr_enabled = var.dynamodb_point_in_time_recovery
}

module "iam" {
  source      = "../../modules/iam"
  name_prefix = local.name_prefix
  common_tags = local.common_tags

  # THE WIRING: dynamodb outputs → iam input
  dynamodb_resource_arns = [
    module.dynamodb.events_table_arn,
    module.dynamodb.registrations_table_arn,
    "${module.dynamodb.registrations_table_arn}/index/*",
  ]
}

locals {
  # Project root = 3 levels up from terraform/environments/dev/
  repo_root = abspath("${path.module}/../../..")

  # Table names come straight from the dynamodb module outputs — no drift possible
  lambda_env = {
    EVENTS_TABLE        = module.dynamodb.events_table_name
    REGISTRATIONS_TABLE = module.dynamodb.registrations_table_name
    LOG_LEVEL           = "INFO"
  }
}

module "lambda_list_events" {
  source                = "../../modules/lambda_function"
  function_name         = "${local.name_prefix}-list-events"
  description           = "GET /events — list all events"
  handler_app_dir       = "${local.repo_root}/lambda/list_events"
  common_dir            = "${local.repo_root}/lambda/common"
  role_arn              = module.iam.lambda_exec_role_arn
  environment_variables = local.lambda_env
  common_tags           = local.common_tags
}

module "lambda_register" {
  source                = "../../modules/lambda_function"
  function_name         = "${local.name_prefix}-register"
  description           = "POST /register — register for an event"
  handler_app_dir       = "${local.repo_root}/lambda/register"
  common_dir            = "${local.repo_root}/lambda/common"
  role_arn              = module.iam.lambda_exec_role_arn
  environment_variables = local.lambda_env
  common_tags           = local.common_tags
}

module "lambda_get_registrations" {
  source                = "../../modules/lambda_function"
  function_name         = "${local.name_prefix}-get-registrations"
  description           = "GET /registrations/{email} — view a person's registrations"
  handler_app_dir       = "${local.repo_root}/lambda/get_registrations"
  common_dir            = "${local.repo_root}/lambda/common"
  role_arn              = module.iam.lambda_exec_role_arn
  environment_variables = local.lambda_env
  common_tags           = local.common_tags
}

module "lambda_cancel_registration" {
  source                = "../../modules/lambda_function"
  function_name         = "${local.name_prefix}-cancel-registration"
  description           = "DELETE /registration/{id} — cancel a registration"
  handler_app_dir       = "${local.repo_root}/lambda/cancel_registration"
  common_dir            = "${local.repo_root}/lambda/common"
  role_arn              = module.iam.lambda_exec_role_arn
  environment_variables = local.lambda_env
  common_tags           = local.common_tags
}