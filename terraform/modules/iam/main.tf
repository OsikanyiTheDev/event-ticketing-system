terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 1) Trust policy — only Lambda may assume this role
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    sid     = "AllowLambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.name_prefix}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.common_tags
}

# 2) CloudWatch Logs (AWS-managed policy)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3) Custom DynamoDB policy — resources come from a VARIABLE, never "*"
data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    sid    = "AccessEventsAndRegistrations"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
    ]

    resources = var.dynamodb_resource_arns   # ← injected, not hard-coded
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "${var.name_prefix}-lambda-dynamodb"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}