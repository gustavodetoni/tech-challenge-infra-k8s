# Diagrama De Componentes

```mermaid
flowchart LR
    user[Cliente/Admin] --> gateway[API Gateway]
    gateway --> auth[Lambda Auth CPF]
    gateway --> eks[EKS]
    eks --> api[API Principal Go]
    api --> db[(RDS PostgreSQL)]
    eks --> obs[Datadog/New Relic]
    gateway --> obs
```

