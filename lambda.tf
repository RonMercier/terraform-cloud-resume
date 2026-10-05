resource "aws_lambda_function" "visitor_counter" {
  function_name = "visitor-counter-lambda"
  role          = aws_iam_role.visitor_function_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 10
  memory_size   = 128

  filename = "placeholder.zip"

  reserved_concurrent_executions = 5

  environment {
    variables = {
      TABLE_NAME = "visitorCount"
    }
  }

  tags = {
    "lambda:createdBy" = "SAM"
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }
}
