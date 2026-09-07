# Ordem De Deploy

Esta ordem evita dependencia circular entre rede, banco, Lambda e aplicacao.

## 1. Infra Kubernetes, Base

Repositorio: `tech-challenge-infra-k8s`

Execute o workflow manual com:

```text
action=apply
environment=homolog
deploy_kubernetes=no
deploy_datadog=no
```

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

Execute o workflow manual com:

```text
action=apply
environment=homolog
```

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

Depois desta etapa, configure o secret `DATABASE_URL` no repositorio `tech-challenge-infra-k8s` usando o template gerado e a senha definida em `TF_VAR_DB_PASSWORD`.

## 3. Infra Kubernetes, Aplicacao E NLB

Repositorio: `tech-challenge-infra-k8s`

Execute o workflow manual novamente com:

```text
action=apply
environment=homolog
deploy_kubernetes=yes
deploy_datadog=yes
```

Nesta etapa sao aplicados os manifests Kubernetes da API principal e, quando o Service `LoadBalancer` estiver pronto, o workflow imprime no resumo o `api_gateway_integration_uri` esperado pelo API Gateway.

O Datadog Agent e instalado somente se o secret `DATADOG_API_KEY` estiver configurado.

## 4. Lambda Auth

Repositorio: `tech-challenge-auth-lambda`

Execute o workflow manual com:

```text
action=apply
environment=homolog
```

Consome os states de K8s e Database e cria:

- Lambda de autenticacao CPF/CNPJ.
- IAM role da Lambda.
- VPC config em subnets privadas.
- Variaveis de ambiente para RDS e JWT.

Outputs consumidos pelo API Gateway:

- `function_name`.
- `function_invoke_arn`.

## 5. Infra Kubernetes, API Gateway Protegido

Repositorio: `tech-challenge-infra-k8s`

Com os outputs da Lambda e do NLB disponiveis, execute novo `apply` informando:

- `api_gateway_integration_uri`.
- `auth_lambda_invoke_arn`.
- `auth_lambda_function_name`.

Nessa etapa o API Gateway passa a rotear:

- `POST /auth/cpf` para a Lambda.
- rotas publicas/admin para a API principal.
- rotas sensiveis `/client` com Lambda Authorizer.

## 6. Aplicacao Principal

Repositorio: `tech-challenge-project`

Execute o workflow manual quando precisar trocar a imagem da API:

```text
action=apply
environment=homolog
image_tag=latest ou versao publicada
run_migrations=yes
```

Esse workflow nao provisiona infraestrutura. Ele usa o cluster existente, executa migrations via Job Kubernetes e atualiza a imagem do Deployment.

## Destroy

Para gravacao no AWS Academy, a ordem recomendada de destroy e:

```text
1. tech-challenge-project              action=destroy
2. tech-challenge-auth-lambda          action=destroy
3. tech-challenge-infra-database       action=destroy
4. tech-challenge-infra-k8s            action=destroy
```

Use `homolog` para demonstracao. Em `prod`, o RDS pode ter protecao contra delecao.
