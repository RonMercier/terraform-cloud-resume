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

resource "aws_iam_role" "visitor_function_role" {
  name               = "portfolio-app-VisitorFunctionRole-V8k9KVV0iTMO"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    "lambda:createdBy" = "SAM"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.visitor_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "visitor_function_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      aws_dynamodb_table.visitor_count.arn,
      "${aws_dynamodb_table.visitor_count.arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "visitor_function_role_policy0" {
  name   = "VisitorFunctionRolePolicy0"
  role   = aws_iam_role.visitor_function_role.id
  policy = data.aws_iam_policy_document.visitor_function_dynamodb.json
}
