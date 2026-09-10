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

O deploy e executado manualmente pelo GitHub Actions para facilitar a demonstracao no AWS Academy e permitir destruir os recursos depois da gravacao.
O gatilho automatico por `push` esta comentado no workflow e deve ser habilitado apenas quando as branches de homologacao/producao estiverem configuradas.

Antes do `terraform init`, o workflow executa um bootstrap do backend S3. Esse passo cria o bucket de state quando ele nao existir e cria um state vazio valido quando o objeto `tech-challenge/k8s/<ambiente>.tfstate` tiver sido removido. Isso evita falhas de `HeadObject 403` comuns em contas AWS Academy quando o objeto nao existe e a role do lab nao recebe permissao de listagem suficiente para o S3 retornar `404`.

Se o bucket configurado em `TF_STATE_BUCKET` pertencer a outra conta ou a uma sessao antiga sem acesso, crie/defina um novo bucket unico para o lab atual e rode novamente a ordem de deploy desde a primeira etapa.

Fluxo previsto:

```text
pull_request -> terraform fmt/validate + kustomize build
Run workflow -> action=apply, environment=homolog
Run workflow -> action=destroy, environment=homolog
```

Inputs do workflow manual:

```text
action                      apply ou destroy
environment                 homolog ou prod
deploy_kubernetes           yes para aplicar manifests da API
deploy_datadog              yes para instalar/atualizar o Datadog Agent
api_gateway_integration_uri ARN do listener NLB da API
auth_lambda_invoke_arn      Invoke ARN da Lambda Auth
auth_lambda_function_name   Nome da Lambda Auth
```

## Ordem De Deploy

1. Aplicar este repositorio primeiro com `deploy_kubernetes=no` e `deploy_datadog=no` para criar VPC, EKS, API Gateway e security group da Lambda.
2. Aplicar `tech-challenge-infra-database` para criar o RDS usando os outputs de rede.
3. Configurar o secret `DATABASE_URL` neste repositorio com o output do banco.
4. Reaplicar este repositorio com `deploy_kubernetes=yes` para criar os manifests da API e obter o ARN do listener do NLB no resumo do workflow.
5. Aplicar `tech-challenge-auth-lambda` para criar a Lambda usando os outputs do banco e da rede.
6. Reaplicar este repositorio informando `api_gateway_integration_uri`, `auth_lambda_invoke_arn` e `auth_lambda_function_name` para fechar as rotas protegidas do API Gateway.

Mais detalhes: [docs/architecture/deployment-order.md](docs/architecture/deployment-order.md)

## Secrets Para Subida

Secrets GitHub:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
TF_STATE_BUCKET
DATABASE_URL
JWT_SECRET
EKS_SERVICE_ROLE_ARN opcional
BREVO_API_KEY opcional
BREVO_SENDER_EMAIL opcional
DATADOG_API_KEY opcional
```

Os valores de API Gateway e Lambda nao precisam ficar salvos como variables no GitHub para a primeira versao.
Eles podem ser informados diretamente nos inputs do `Run workflow` quando forem gerados pelos workflows anteriores.

## Compatibilidade AWS Academy

O AWS Academy aplica politicas restritivas para IAM, incluindo bloqueios para `iam:GetRole`, `iam:CreateRole`, `iam:PassRole` na role de sessao `voclabs` e `iam:CreateOpenIDConnectProvider`.
Por isso, o modulo EKS foi fixado na serie `~> 18.0`, que nao usa o data source `aws_iam_session_context`.

As versoes mais novas do modulo EKS, como `v20`, consultam o contexto da sessao IAM durante o `plan` e falham no lab antes da criacao do cluster.
No AWS Academy, o cluster e o node group reutilizam por padrao a role pre-criada `LabRole`, que e a role esperada para ser passada aos servicos AWS.
O IRSA/OIDC tambem fica desabilitado para evitar criacao de IAM OpenID Connect Provider, que nao e necessario para a demonstracao com Datadog via API key.
Use `EKS_SERVICE_ROLE_ARN` apenas se o seu lab informar outra role passavel para EKS.

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
