resource "aws_apigatewayv2_api" "http_api" {
  name          = "portfolio-app"
  protocol_type = "HTTP"
  version       = "1.0"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type"]
    allow_methods     = ["GET", "OPTIONS"]
    allow_origins = [
      "https://ron-mercier101.com",
      "https://securebydefault.io",
    ]
    max_age = 86400
  }

  tags = {
    "httpapi:createdBy" = "SAM"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
  connection_type        = "INTERNET"
}

resource "aws_apigatewayv2_route" "count_get" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /count"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = false
    throttling_burst_limit   = 20
    throttling_rate_limit    = 10
  }
}
