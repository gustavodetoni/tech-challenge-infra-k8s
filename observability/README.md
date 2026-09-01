# Observabilidade

Este repositorio usa Datadog para atender o requisito de monitoramento do Tech Challenge.

## Escopo Monitorado

- Latencia das APIs via API Gateway e APM.
- CPU e memoria dos pods no EKS.
- Healthchecks via probes Kubernetes.
- Uptime do deployment da API.
- Logs dos containers com tag `service:tech-challenge-api`.
- Falhas em rotas de ordens de servico por logs e status HTTP.

## Instalar Agent

Crie o namespace e o secret com a API key a partir do exemplo:

```bash
kubectl create namespace datadog
cp observability/datadog-secret.example.yaml observability/datadog-secret.yaml
kubectl apply -f observability/datadog-secret.yaml
```

Instale o chart:

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
helm upgrade --install datadog-agent datadog/datadog \
  --namespace datadog \
  --values observability/datadog-values.yaml
```

## Dashboards Esperados

- Volume diario de ordens de servico.
- Tempo medio de execucao por status.
- Erros 4xx/5xx da API.
- Erros em integracoes, incluindo Lambda Auth e notificacoes.
- CPU/memoria por namespace, deployment e pod.
