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