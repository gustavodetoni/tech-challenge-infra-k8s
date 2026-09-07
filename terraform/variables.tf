variable "project_name" {
  description = "Nome base usado nos recursos criados na AWS."
  type        = string
  default     = "tech-challenge"
}

variable "aws_region" {
  description = "Regiao AWS onde os recursos serao criados."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de deploy."
  type        = string
  default     = "homolog"
}

variable "cluster_version" {
  description = "Versao do Kubernetes usada no EKS."
  type        = string
  default     = "1.33"
}

variable "aws_academy_service_role_name" {
  description = "Nome da IAM Role pre-criada pelo AWS Academy para ser passada aos servicos AWS."
  type        = string
  default     = "LabRole"
}

variable "eks_role_arn" {
  description = "ARN de uma IAM Role existente para EKS/control plane/node group. Se vazio, usa arn:aws:iam::<account>:role/LabRole."
  type        = string
  default     = ""
}

variable "api_gateway_enabled" {
  description = "Habilita o API Gateway HTTP."
  type        = bool
  default     = true
}

variable "api_gateway_integration_uri" {
  description = "URI do backend da API principal. Para VPC Link, informe o ARN do listener do NLB."
  type        = string
  default     = ""
}

variable "api_gateway_protected_client_routes" {
  description = "Rotas de cliente protegidas pelo Lambda Authorizer CPF/CNPJ."
  type        = set(string)
  default = [
    "GET /client/service-orders/{code}",
    "GET /client/service-orders/{code}/status",
    "POST /client/service-orders/{code}/budget/approve",
    "POST /client/service-orders/{code}/budget/reject",
  ]
}

variable "auth_lambda_invoke_arn" {
  description = "Invoke ARN da Lambda de autenticacao CPF/CNPJ."
  type        = string
  default     = ""
}

variable "auth_lambda_function_name" {
  description = "Nome da Lambda de autenticacao CPF/CNPJ para permissao de invocacao pelo API Gateway."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags aplicadas aos recursos."
  type        = map(string)

  default = {
    Project = "tech-challenge"
    Managed = "terraform"
  }
}
