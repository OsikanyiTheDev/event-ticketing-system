terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ───────── Events table: one row per event ─────────
resource "aws_dynamodb_table" "events" {
  name         = "${var.name_prefix}-events"
  billing_mode = "PAY_PER_REQUEST" # on-demand: idle = free
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.pitr_enabled
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.common_tags
}

# ───────── Registrations table: one row per sign-up ─────────
resource "aws_dynamodb_table" "registrations" {
  name         = "${var.name_prefix}-registrations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "registration_id"

  attribute {
    name = "registration_id"
    type = "S"
  }

  # backs the GSI
  attribute {
    name = "email"
    type = "S"
  }

  # GSI: lets GET /registrations/{email} query by email fast
  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.pitr_enabled
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.common_tags
}