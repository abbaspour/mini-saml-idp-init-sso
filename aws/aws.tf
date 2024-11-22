# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "idp_init_lambda_exec_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

locals {
  auth0_tenant = split(".", var.auth0_domain)[0]
}

# Create the Lambda function
resource "aws_lambda_function" "saml_lambda" {
  function_name = "idp-init-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  # Ensure this path matches where your deployment package zip is located
  filename = "lambda-deployment-package.zip" # Replace with your path
  source_code_hash               = filesha256("lambda-deployment-package.zip")


  # Environment variables (optional)
  environment {
    variables = {
      SAML_ISSUER = "urn:${var.cf_worker_name}.${var.cf_workers_subdomain}"
      SAML_AUDIENCE = "urn:auth0:${local.auth0_tenant}:${auth0_connection.idp-init-saml.name}"
      SAML_REDIRECT_LOCATION = "https://${var.auth0_domain}/login/callback?connection=${auth0_connection.idp-init-saml.name}"
    }
  }
}

# Create API Gateway REST API
resource "aws_apigatewayv2_api" "saml_api" {
  name          = "idp-init-lambda"
  protocol_type = "HTTP"
}

# Create API Gateway integration with the Lambda function
resource "aws_apigatewayv2_integration" "saml_integration" {
  api_id           = aws_apigatewayv2_api.saml_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.saml_lambda.invoke_arn
}

# Create an API route
resource "aws_apigatewayv2_route" "saml_route" {
  api_id    = aws_apigatewayv2_api.saml_api.id
  route_key = "GET /" # HTTP method and path
  target    = "integrations/${aws_apigatewayv2_integration.saml_integration.id}"
}

# Deploy API stage
resource "aws_apigatewayv2_stage" "saml_stage" {
  api_id      = aws_apigatewayv2_api.saml_api.id
  name        = "$default"
  auto_deploy = true
}

# Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.saml_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.saml_api.execution_arn}/*/*"
}

# Output the public endpoint URL
output "saml_api_endpoint" {
  value = aws_apigatewayv2_api.saml_api.api_endpoint
}
