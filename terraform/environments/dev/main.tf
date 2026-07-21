###############################################################################
# environments/dev/main.tf  — THE COMPOSITION LAYER
# Wires modules together and injects environment-specific settings.
###############################################################################

module "dynamodb" {
  source       = "../../modules/dynamodb"
  name_prefix  = local.name_prefix
  common_tags  = local.common_tags
  pitr_enabled = var.dynamodb_point_in_time_recovery
}

# SNS topic for confirmation emails (must come BEFORE iam, which needs its ARN)
module "sns" {
  source           = "../../modules/sns"
  topic_name       = "${local.name_prefix}-confirmations"
  display_name     = "Event Registration Confirmations"
  subscriber_email = var.notification_email
  common_tags      = local.common_tags
}

module "iam" {
  source      = "../../modules/iam"
  name_prefix = local.name_prefix
  common_tags = local.common_tags

  # THE WIRING: dynamodb module outputs (table ARNs) → iam module input
  dynamodb_resource_arns = [
    module.dynamodb.events_table_arn,
    module.dynamodb.registrations_table_arn,
    "${module.dynamodb.registrations_table_arn}/index/*",
  ]

  # Grant the Lambda role permission to publish confirmations
  sns_topic_arn = module.sns.topic_arn
  enable_sns    = true
}

locals {
  # Project root is 3 levels up from terraform/environments/dev/
  repo_root = abspath("${path.module}/../../..")

  # Env vars shared by every Lambda function. Table names come straight from
  # the dynamodb module's outputs — so the functions and tables can never drift.
  lambda_env = {
    EVENTS_TABLE        = module.dynamodb.events_table_name
    REGISTRATIONS_TABLE = module.dynamodb.registrations_table_name
    LOG_LEVEL           = "INFO"
  }
}

# ───────────────────── The 4 Lambda functions ────────────────────
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
  source          = "../../modules/lambda_function"
  function_name   = "${local.name_prefix}-register"
  description     = "POST /register — register for an event"
  handler_app_dir = "${local.repo_root}/lambda/register"
  common_dir      = "${local.repo_root}/lambda/common"
  role_arn        = module.iam.lambda_exec_role_arn
  environment_variables = merge(local.lambda_env, {
    SNS_TOPIC_ARN = module.sns.topic_arn # only register publishes confirmations
  })
  common_tags = local.common_tags
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

# ───────────────────── The REST API (public URLs) ────────────────────
module "api_gateway" {
  source      = "../../modules/api_gateway"
  api_name    = "${local.name_prefix}-api"
  stage_name  = var.environment
  common_tags = local.common_tags

  # Hand each Lambda's invoke ARN + name to the API module so it can wire
  # routes → integrations → invoke permissions.
  lambdas = {
    list_events = {
      invoke_arn    = module.lambda_list_events.invoke_arn
      function_name = module.lambda_list_events.function_name
    }
    register = {
      invoke_arn    = module.lambda_register.invoke_arn
      function_name = module.lambda_register.function_name
    }
    get_registrations = {
      invoke_arn    = module.lambda_get_registrations.invoke_arn
      function_name = module.lambda_get_registrations.function_name
    }
    cancel_registration = {
      invoke_arn    = module.lambda_cancel_registration.invoke_arn
      function_name = module.lambda_cancel_registration.function_name
    }
  }
}
