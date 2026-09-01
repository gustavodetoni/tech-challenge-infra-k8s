# Observabilidade

A escolha padrao deste repositorio e Datadog.

## O Que Sera Monitorado

- Latencia do API Gateway.
- Latencia e erros da API principal.
- CPU e memoria de pods no EKS.
- Healthchecks por probes Kubernetes.
- Uptime do deployment `tech-challenge-api`.
- Logs dos containers com tags de ambiente, servico e versao.
- Falhas em fluxos de ordem de servico por status HTTP e logs.

## Dashboards Necessarios

- Volume diario de ordens de servico.
- Tempo medio por status: diagnostico, execucao, finalizacao e entrega.
- Erros 4xx/5xx por rota.
- Falhas de integracao: Lambda Auth, RDS e notificacoes.
- Capacidade Kubernetes: CPU, memoria, replicas e restarts.

## Alertas Necessarios

- API indisponivel ou healthcheck falhando.
- Alta taxa de erro 5xx.
- Latencia p95 acima do limite definido.
- Pods reiniciando em loop.
- RDS com conexoes proximas do limite.
- Falhas em aprovacao/rejeicao de orcamentos.

