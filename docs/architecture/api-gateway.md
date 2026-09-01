# API Gateway

O API Gateway HTTP e a entrada publica da plataforma.

## Rotas

| Rota | Backend | Autenticacao |
| --- | --- | --- |
| `POST /auth/cpf` | Lambda Auth CPF/CNPJ | Publica |
| `ANY /{proxy+}` | API principal no EKS | Sem authorizer no Gateway |
| `GET /client/service-orders/{code}` | API principal no EKS | Lambda Authorizer |
| `GET /client/service-orders/{code}/status` | API principal no EKS | Lambda Authorizer |
| `POST /client/service-orders/{code}/budget/approve` | API principal no EKS | Lambda Authorizer |
| `POST /client/service-orders/{code}/budget/reject` | API principal no EKS | Lambda Authorizer |

As rotas de cliente tambem sao validadas pela API principal, que aceita apenas JWT com `type=CLIENT` emitido pela Lambda.

## Integracao Com Kubernetes

O Service Kubernetes `tech-challenge-api` cria um Load Balancer interno do tipo NLB. O API Gateway acessa esse NLB via VPC Link.

O ARN do listener do NLB deve ser informado em:

```text
TF_VAR_api_gateway_integration_uri
```

