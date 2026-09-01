output "environment" {
  value = var.environment
}

output "vpc_id" {
  description = "ID da VPC usada pelo EKS e pelos recursos privados."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Subnets privadas para EKS, RDS e Lambda."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Subnets publicas usadas por load balancers externos."
  value       = module.vpc.public_subnets
}

output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS."
  value       = module.eks.cluster_endpoint
}

output "eks_node_security_group_id" {
  description = "Security group dos nodes do EKS."
  value       = module.eks.node_security_group_id
}

output "auth_lambda_security_group_id" {
  description = "Security group usado pela Lambda de autenticacao para acessar recursos privados."
  value       = aws_security_group.auth_lambda.id
}

output "api_gateway_endpoint" {
  description = "Endpoint publico do API Gateway."
  value       = try(aws_apigatewayv2_api.main[0].api_endpoint, null)
}
