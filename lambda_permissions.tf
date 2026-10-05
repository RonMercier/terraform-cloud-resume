resource "aws_lambda_permission" "api_get_count" {
  statement_id  = "portfolio-app-VisitorFunctionApiEventPermission-77OnwUIsjag4"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/GET/count"
}
