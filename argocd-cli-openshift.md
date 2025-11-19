# Procedimento — Utilização do ArgoCD CLI

## 1. Download do binário ArgoCD CLI

Para baixar o binário do ArgoCD CLI, acesse o endpoint `/help` da instância do Argo:

https://.nuvem.bb.com.br/help

---

## 2. Capturar senha de instalação e URL da instância

### Obter senha do usuário `admin`

    ```bash
    ADMIN_PASSWD=$(
      oc get secret "<nome-da-instancia-do-argo>-cluster" \
      -n "<namespace-da-instancia-do-argo>" \
      -o jsonpath='{.data.admin\.password}' | base64 -d
    )

Obter URL da instância (rota do servidor)

    ```bash
    SERVER_URL=$(
      oc get route "<nome-da-instancia-do-argo>-server" \
      -n "<namespace-da-instancia-do-argo>" \
      -o jsonpath='{.spec.host}'
    )

## 3. Login no argoCD

    argocd login "$SERVER_URL" \
      --username admin \
      --password "$ADMIN_PASSWD" \
      --grpc-web \
      --insecure

## 4. Verificar cluster stats

Para utilizar o comando argocd admin cluster stats, informe o nome do HAProxy do Redis-HA:

    argocd admin cluster stats \
      --redis-name "<nome-da-instancia-do-argo>-redis-ha-haproxy"

## 5. Configurar a Secret do Redis (se necessário)

Caso o comando acima retorne erro de autenticação do Redis, crie a Secret argocd-redis contendo a senha inicial.

Arquivo redis.yaml:

```yaml

    apiVersion: v1
    kind: Secret
    metadata:
      name: argocd-redis
      namespace: "<namespace-da-instancia-do-argo>"
    type: Opaque
    data:
      auth: <senha-em-base64>

>A senha pode ser obtida no namespace da instância do Argo, geralmente no Secret redis-initial.

Observação
Certifique-se de aplicar a Secret com:

```bash
oc apply -f redis.yaml
