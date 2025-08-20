resource "aws_apigatewayv2_api" "portal_api" {
  name          = "${var.project_name}-portal-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = [
      "http://localhost:3000",          # dev
    ]
    allow_methods = ["OPTIONS", "POST", "GET"] # include methods you use
    allow_headers = [
      "Content-Type",
      "Authorization",
      "X-Amz-Date",
      "X-Api-Key",
      "X-Amz-Security-Token",
      "X-Amz-User-Agent"
    ]
    expose_headers     = ["*"]
    allow_credentials  = false
    max_age            = 3600
  }
}

resource "aws_apigatewayv2_integration" "scale_up" {
  api_id                 = aws_apigatewayv2_api.portal_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.scale_up_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "run_tests" {
  api_id    = aws_apigatewayv2_api.portal_api.id
  route_key = "POST /run"
  target    = "integrations/${aws_apigatewayv2_integration.scale_up.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.portal_api.id
  name        = "$default"
  auto_deploy = true
}

# Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw_invoke_scale_up" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.scale_up_function_name
  principal     = "apigateway.amazonaws.com"
  # allow all routes under this api
  source_arn    = "${aws_apigatewayv2_api.portal_api.execution_arn}/*/*"
}
