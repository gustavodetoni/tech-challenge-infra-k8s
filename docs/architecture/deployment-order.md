# Ordem De Deploy

Esta ordem evita dependencia circular entre rede, banco, Lambda e aplicacao.

## 1. Infra Kubernetes

Repositorio: `tech-challenge-infra-k8s`

Cria:

- VPC.
- Subnets publicas e privadas.
- Cluster EKS.
- Node group gerenciado.
- Security group usado pela Lambda Auth.
- API Gateway HTTP.

Outputs consumidos pelos outros repos:

- `vpc_id`.
- `private_subnet_ids`.
- `eks_node_security_group_id`.
- `auth_lambda_security_group_id`.
- `cluster_name`.
- `api_gateway_endpoint`.

## 2. Infra Database

Repositorio: `tech-challenge-infra-database`

Consome o state do `tech-challenge-infra-k8s` e cria:

- RDS PostgreSQL privado.
- Security group permitindo acesso dos nodes EKS e da Lambda Auth.
- Parameter group PostgreSQL.
- Logs PostgreSQL no CloudWatch.

Outputs consumidos pela Lambda e pela aplicacao:

- `database_host`.
- `database_port`.
- `database_name`.
- `database_url_template`.

## 3. Lambda Auth

Repositorio: `tech-challenge-auth-lambda`

Consome os states de K8s e Database e cria:

- Lambda de autenticacao CPF/CNPJ.
- IAM role da Lambda.
- VPC config em subnets privadas.
- Variaveis de ambiente para RDS e JWT.

Outputs consumidos pelo API Gateway:

- `function_name`.
- `function_invoke_arn`.

## 4. Infra Kubernetes, Segunda Aplicacao

Repositorio: `tech-challenge-infra-k8s`

Com os outputs da Lambda disponiveis, execute novo deploy informando:

- `AUTH_LAMBDA_INVOKE_ARN`.
- `AUTH_LAMBDA_FUNCTION_NAME`.
- `API_GATEWAY_INTEGRATION_URI`.

Nessa etapa o API Gateway passa a rotear:

- `POST /auth/cpf` para a Lambda.
- rotas publicas/admin para a API principal.
- rotas sensiveis `/client` com Lambda Authorizer.

