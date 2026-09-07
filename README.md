# Tech Challenge Infra Kubernetes

Infraestrutura Kubernetes da aplicacao principal da oficina, incluindo rede, cluster, API Gateway, autoscaling e observabilidade.

## Repositorios Da Entrega

- Aplicacao principal: https://github.com/gustavodetoni/tech-challenge-project
- Lambda Auth CPF/CNPJ: https://github.com/gustavodetoni/tech-challenge-auth-lambda
- Infra Kubernetes: https://github.com/gustavodetoni/tech-challenge-infra-k8s
- Infra Database: https://github.com/gustavodetoni/tech-challenge-infra-database

## Proposito

Este repositorio provisiona e opera a camada de execucao da aplicacao principal em Kubernetes. Ele tambem concentra a entrada HTTP via API Gateway e a integracao com monitoramento.

## Tecnologias

- Terraform
- AWS EKS
- AWS API Gateway
- Kubernetes
- Kustomize
- HPA
- Datadog ou New Relic
- GitHub Actions

## Estrutura

```text
terraform/              Infraestrutura cloud do cluster e gateway
k8s/base/               Manifests reutilizaveis
k8s/overlays/homolog/   Ambiente de homologacao
k8s/overlays/prod/      Ambiente de producao
observability/          Helm values e instrucoes Datadog
docs/architecture/      Diagramas e decisoes do repo
```

## Execucao Local

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
terraform -chdir=terraform init
terraform -chdir=terraform validate
kubectl kustomize k8s/overlays/homolog
```

Este repositorio tambem publica outputs consumidos pelos repositorios `tech-challenge-infra-database` e `tech-challenge-auth-lambda`, como VPC, subnets privadas, security group dos nodes do EKS e security group da Lambda.

## Deploy

O workflow de deploy esta versionado em `.github/workflows/deploy.yml`, mas o deploy automatico esta temporariamente desabilitado para o primeiro push do repositorio.
Quando as variaveis AWS/Terraform/API Gateway estiverem configuradas, o workflow deve ser reativado para deploy nas branches de homologacao e producao.

Fluxo previsto:

```text
pull_request -> terraform fmt/validate + kustomize build
homolog      -> terraform apply homolog + kubectl apply
main         -> terraform apply prod + kubectl apply
```

## Ordem De Deploy

1. Aplicar este repositorio primeiro para criar VPC, EKS, API Gateway e security group da Lambda.
2. Aplicar `tech-challenge-infra-database` para criar o RDS usando os outputs de rede.
3. Aplicar `tech-challenge-auth-lambda` para criar a Lambda usando os outputs do banco e da rede.
4. Reaplicar este repositorio com os outputs da Lambda e o ARN do listener do NLB para fechar as rotas do API Gateway.

Mais detalhes: [docs/architecture/deployment-order.md](docs/architecture/deployment-order.md)

## Variaveis Pendentes Para Subida

Secrets GitHub:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
TF_STATE_BUCKET
DATABASE_URL
JWT_SECRET
BREVO_API_KEY
BREVO_SENDER_EMAIL
DATADOG_API_KEY
```

Variables GitHub:

```text
API_GATEWAY_INTEGRATION_URI
AUTH_LAMBDA_INVOKE_ARN
AUTH_LAMBDA_FUNCTION_NAME
```

## Arquitetura

```text
Internet
  -> API Gateway
      -> VPC Link / Load Balancer
          -> EKS
              -> Deployment API Principal
              -> HPA
              -> Observability Agent

Lambda Auth CPF
  -> Security Group compartilhado
      -> RDS PostgreSQL
```

## API Gateway

O proxy geral encaminha para a API no EKS. Apenas as rotas sensiveis de cliente usam Lambda Authorizer:

```text
GET  /client/service-orders/{code}
GET  /client/service-orders/{code}/status
POST /client/service-orders/{code}/budget/approve
POST /client/service-orders/{code}/budget/reject
```

Detalhes: [docs/architecture/api-gateway.md](docs/architecture/api-gateway.md)

## Observabilidade

A integracao padrao e Datadog via Helm chart. Os valores ficam em:

```text
observability/datadog-values.yaml
```

Detalhes: [docs/architecture/observability.md](docs/architecture/observability.md)

## Links

- Repositorio: https://github.com/gustavodetoni/tech-challenge-infra-k8s
- Swagger da API principal: https://github.com/gustavodetoni/tech-challenge-project/blob/main/docs/swagger.yaml
- Postman da API principal: https://github.com/gustavodetoni/tech-challenge-project/blob/main/docs/collections/tech-challenge.postman_collection.json
- Deploy homologacao: sera atualizado apos o primeiro deploy cloud.
- Deploy producao: sera atualizado apos o primeiro deploy cloud.
