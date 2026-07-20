terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ──────────────────────────── The API ────────────────────────────
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "Event Registration & Ticketing System REST API"
  tags        = var.common_tags
}

# ──────────────────── Path resources (the URL tree) ────────────────────
# We build them explicitly because nested ones ({email}, {id}) depend on their
# parent's id (a circular problem for for_each).
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "events"
}
resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "register"
}
resource "aws_api_gateway_resource" "registrations" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "registrations"
}
resource "aws_api_gateway_resource" "registrations_email" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.registrations.id
  path_part   = "{email}" # path parameter → event.pathParameters.email
}
resource "aws_api_gateway_resource" "registration" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "registration"
}
resource "aws_api_gateway_resource" "registration_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.registration.id
  path_part   = "{id}" # path parameter → event.pathParameters.id
}

# ──────────────────── Route table ────────────────────
# Maps a logical route key → (which leaf resource, HTTP method, which Lambda).
# for_each below turns this into the 4 method/integration/permission triples.
locals {
  routes = {
    list_events         = { resource_id = aws_api_gateway_resource.events.id, http_method = "GET", lambda = "list_events" }
    register            = { resource_id = aws_api_gateway_resource.register.id, http_method = "POST", lambda = "register" }
    get_registrations   = { resource_id = aws_api_gateway_resource.registrations_email.id, http_method = "GET", lambda = "get_registrations" }
    cancel_registration = { resource_id = aws_api_gateway_resource.registration_id.id, http_method = "DELETE", lambda = "cancel_registration" }
  }
}

# ──────────────────── HTTP methods ────────────────────
resource "aws_api_gateway_method" "route" {
  for_each      = local.routes
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value.resource_id
  http_method   = each.value.http_method
  authorization = "NONE" # public API (auth added later if needed)
}

# ──────────────────── Lambda proxy integrations ────────────────────
resource "aws_api_gateway_integration" "route" {
  for_each                = local.routes
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = each.value.resource_id
  http_method             = aws_api_gateway_method.route[each.key].http_method
  integration_http_method = "POST" # Lambda is ALWAYS invoked via POST
  type                    = "AWS_PROXY"
  uri                     = var.lambdas[each.value.lambda].invoke_arn
}

# ──────────── Grant API Gateway permission to call each Lambda ────────────
resource "aws_lambda_permission" "route" {
  for_each      = local.routes
  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambdas[each.value.lambda].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# ──────────────────── CORS preflight (OPTIONS) on each route ────────────────────
# Browsers send an OPTIONS request before cross-origin GET/POST/DELETE. This
# MOCK integration answers with 200 + CORS headers so the browser allows the
# real request through.
resource "aws_api_gateway_method" "options" {
  for_each      = local.routes
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value.resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each    = local.routes
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_id
  http_method = "OPTIONS"
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.options]
}

resource "aws_api_gateway_method_response" "options" {
  for_each    = local.routes
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_id
  http_method = "OPTIONS"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.options]
}

resource "aws_api_gateway_integration_response" "options" {
  for_each    = local.routes
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_id
  http_method = "OPTIONS"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [
    aws_api_gateway_integration.options,
    aws_api_gateway_method_response.options,
  ]
}

# ──────────────────── Deployment + Stage (the public URL) ────────────────────
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # Re-deploy whenever the API structure changes
  triggers = {
    redeployment = sha1(jsonencode(local.routes))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.route,
    aws_api_gateway_integration.options,
    aws_api_gateway_method_response.options,
    aws_api_gateway_integration_response.options,
  ]
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
  tags          = var.common_tags
}
