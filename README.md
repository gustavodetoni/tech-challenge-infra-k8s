# Tech Challenge Infra Kubernetes

Infraestrutura Kubernetes da aplicacao principal da oficina, incluindo cluster, API Gateway, autoscaling e observabilidade.

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
docs/architecture/      Diagramas e decisoes do repo
```

## Execucao Local

```bash
terraform -chdir=terraform init
terraform -chdir=terraform validate
kubectl kustomize k8s/overlays/homolog
```

## Deploy

Fluxo previsto:

```text
pull_request -> terraform fmt/validate + kustomize build
homolog      -> terraform apply homolog + kubectl apply
main         -> terraform apply prod + kubectl apply
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
```

## Links

- Swagger/Postman da API principal: pendente
- Deploy homologacao: pendente
- Deploy producao: pendente

