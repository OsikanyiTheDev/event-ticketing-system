terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

data "archive_file" "this" {
  type        = "zip"
  output_path = "${path.module}/build/${var.function_name}.zip"

  source {
    content  = file("${var.handler_app_dir}/app.py")
    filename = "app.py"
  }
  source {
    content  = file("${var.common_dir}/__init__.py")
    filename = "common/__init__.py"
  }
  source {
    content  = file("${var.common_dir}/responses.py")
    filename = "common/responses.py"
  }
  source {
    content  = file("${var.common_dir}/validation.py")
    filename = "common/validation.py"
  }
  source {
    content  = file("${var.common_dir}/errors.py")
    filename = "common/errors.py"
  }
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  description      = var.description
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  role             = var.role_arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = var.environment_variables
  }

  tags = var.common_tags
}