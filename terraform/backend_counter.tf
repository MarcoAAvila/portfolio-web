# =============================================================================
# backend_counter.tf
# Serverless visitor counter: DynamoDB → Lambda → API Gateway HTTP API.
#
# COST RATIONALE:
#   - DynamoDB On-Demand: pay-per-request; Free Tier covers 25 GB + 200M ops/month.
#   - Lambda: 1M free invocations/month; this workload is well within that limit.
#   - API Gateway HTTP API: ~$1/million requests — significantly cheaper than REST API.
# =============================================================================

# =============================================================================
# 1. DynamoDB
# =============================================================================

resource "aws_dynamodb_table" "visitor_counter" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "portfolio-visitor-counter"
  }
}

resource "aws_dynamodb_table_item" "initial_counter" {
  table_name = aws_dynamodb_table.visitor_counter.name
  hash_key   = aws_dynamodb_table.visitor_counter.hash_key

  item = jsonencode({
    id          = { S = "visits" }
    visit_count = { N = "0" }
  })

  # Terraform manages this item for initial provisioning only.
  # visit_count is incremented by Lambda at runtime; ignoring changes here
  # prevents Terraform from overwriting the live counter back to 0 on apply.
  lifecycle {
    ignore_changes = [item]
  }
}

# =============================================================================
# 2. IAM — Lambda execution role
# =============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "portfolio-lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name = "portfolio-lambda-exec-role"
  }
}

# Least-privilege policy: scoped to this table only, no destructive actions.
data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:PutItem",
    ]
    resources = [aws_dynamodb_table.visitor_counter.arn]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "portfolio-lambda-permissions"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# =============================================================================
# 3. Lambda — package and deploy
# =============================================================================

# The archive provider hashes the source directory so Terraform detects code
# changes and triggers a function update automatically on the next apply.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_src.zip"
}

resource "aws_lambda_function" "visitor_counter" {
  function_name    = "portfolio-visitor-counter"
  description      = "Increments the portfolio visitor counter in DynamoDB"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  handler          = "counter.handler"
  role             = aws_iam_role.lambda_exec.arn
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }

  tags = {
    Name = "portfolio-visitor-counter"
  }
}

# Explicit log group with a retention policy; without this, Lambda auto-creates
# the group with infinite retention, which accumulates CloudWatch storage costs.
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.visitor_counter.function_name}"
  retention_in_days = 14
}

# =============================================================================
# 4. API Gateway HTTP API
# =============================================================================

resource "aws_apigatewayv2_api" "visitor_counter_api" {
  name          = "portfolio-visitor-counter-api"
  protocol_type = "HTTP"
  description   = "HTTP API for the portfolio visitor counter"

  cors_configuration {
    allow_origins = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/portfolio-api"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.visitor_counter_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.visitor_counter_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_visits" {
  api_id    = aws_apigatewayv2_api.visitor_counter_api.id
  route_key = "GET /visits"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_counter_api.execution_arn}/*/*"
}