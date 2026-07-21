terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ───── 1) Trust policy: who is allowed to assume this role? ─────
# Only the AWS Lambda service may use it.
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

# ───── 2) CloudWatch Logs (AWS-managed policy) ─────
# Lets Lambda create log groups/streams and write events.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ───── 3) Custom DynamoDB policy (least-privilege) ─────
# NOTE resources = var.dynamodb_resource_arns (injected!). NEVER "*" here.
# SNS publish permission will be added in Stage 5 when the topic exists.
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

    resources = var.dynamodb_resource_arns
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "${var.name_prefix}-lambda-dynamodb"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

# ───── 4) Optional SNS publish permission (least-privilege, scoped) ─────
# Only created when an SNS topic ARN is provided. Scoped to EXACTLY that topic.
# This is how least-privilege grows: add a narrow permission only when needed.
resource "aws_iam_role_policy" "lambda_sns" {
  count = var.enable_sns ? 1 : 0
  name  = "${var.name_prefix}-lambda-sns"
  role  = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = var.sns_topic_arn
    }]
  })
}
