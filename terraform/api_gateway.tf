locals {
  api_gateway_has_backend     = var.api_gateway_enabled && var.api_gateway_integration_uri != ""
  api_gateway_has_auth_lambda = var.api_gateway_enabled && var.auth_lambda_invoke_arn != "" && var.auth_lambda_function_name != ""
}

resource "aws_security_group" "api_gateway_vpc_link" {
  count = var.api_gateway_enabled ? 1 : 0

  name        = "${var.project_name}-${var.environment}-apigw-vpc-link-sg"
  description = "Security group do VPC Link do API Gateway"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_apigatewayv2_api" "main" {
  count = var.api_gateway_enabled ? 1 : 0

  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["authorization", "content-type", "x-correlation-id"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins = ["*"]
    max_age       = 300
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_apigatewayv2_vpc_link" "main" {
  count = var.api_gateway_enabled ? 1 : 0

  name               = "${var.project_name}-${var.environment}-vpc-link"
  security_group_ids = [aws_security_group.api_gateway_vpc_link[0].id]
  subnet_ids         = module.vpc.private_subnets

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_apigatewayv2_authorizer" "client_jwt" {
  count = local.api_gateway_has_auth_lambda ? 1 : 0

  api_id                            = aws_apigatewayv2_api.main[0].id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = var.auth_lambda_invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${var.project_name}-${var.environment}-client-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

resource "aws_lambda_permission" "api_gateway_authorizer" {
  count = local.api_gateway_has_auth_lambda ? 1 : 0

  statement_id  = "AllowAPIGatewayAuthorizerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/authorizers/${aws_apigatewayv2_authorizer.client_jwt[0].id}"
}

resource "aws_apigatewayv2_integration" "auth_lambda" {
  count = local.api_gateway_has_auth_lambda ? 1 : 0

  api_id                 = aws_apigatewayv2_api.main[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.auth_lambda_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "api_gateway_auth_route" {
  count = local.api_gateway_has_auth_lambda ? 1 : 0

  statement_id  = "AllowAPIGatewayAuthRouteInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "auth_cpf" {
  count = local.api_gateway_has_auth_lambda ? 1 : 0

  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "POST /auth/cpf"
  target    = "integrations/${aws_apigatewayv2_integration.auth_lambda[0].id}"
}

resource "aws_apigatewayv2_integration" "api" {
  count = local.api_gateway_has_backend ? 1 : 0

  api_id             = aws_apigatewayv2_api.main[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = var.api_gateway_integration_uri
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.main[0].id
}

resource "aws_apigatewayv2_route" "api_proxy" {
  count = local.api_gateway_has_backend ? 1 : 0

  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api[0].id}"
}

resource "aws_apigatewayv2_route" "client_protected" {
  for_each = local.api_gateway_has_backend && local.api_gateway_has_auth_lambda ? var.api_gateway_protected_client_routes : toset([])

  api_id             = aws_apigatewayv2_api.main[0].id
  route_key          = each.value
  target             = "integrations/${aws_apigatewayv2_integration.api[0].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.client_jwt[0].id
}

resource "aws_apigatewayv2_stage" "default" {
  count = var.api_gateway_enabled ? 1 : 0

  api_id      = aws_apigatewayv2_api.main[0].id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 200
    throttling_rate_limit  = 100
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}
