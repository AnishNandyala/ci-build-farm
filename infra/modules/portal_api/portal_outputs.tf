output "portal_api_endpoint" {
  value       = aws_apigatewayv2_api.portal_api.api_endpoint
  description = "HTTP API endpoint"
}