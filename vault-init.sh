#!/bin/bash
set -e

VAULT_CONTAINER_NAME="vault"

echo "Waiting for Vault to become healthy..."

# NEW: Wait for Docker healthcheck
until [ "$(docker inspect -f {{.State.Health.Status}} ${VAULT_CONTAINER_NAME})" = "healthy" ]; do
  sleep 3
done

echo "Vault is healthy, proceeding with initialization..."

AWS_REGION="ap-southeast-2"
SECRETS_MANAGER_NAME="willcloud/vault/init"

INIT_STATUS=$(docker exec ${VAULT_CONTAINER_NAME} sh -c 'curl -s http://127.0.0.1:8200/v1/sys/health' | jq -r '.initialized')

if [ "${INIT_STATUS}" = "false" ]; then
  echo "Initializing Vault..."
  docker exec ${VAULT_CONTAINER_NAME} sh -c 'vault operator init -format=json' > /opt/vault/keys.json

  aws secretsmanager create-secret \
    --name "${SECRETS_MANAGER_NAME}" \
    --secret-string file:///opt/vault/keys.json \
    --region ${AWS_REGION} || \
  aws secretsmanager put-secret-value \
    --secret-id "${SECRETS_MANAGER_NAME}" \
    --secret-string file:///opt/vault/keys.json \
    --region ${AWS_REGION}

  ROOT_TOKEN=$(jq -r '.root_token' /opt/vault/keys.json)

else
  echo "Vault already initialized."
  aws secretsmanager get-secret-value \
    --secret-id "${SECRETS_MANAGER_NAME}" \
    --query SecretString \
    --output text \
    --region ${AWS_REGION} > /opt/vault/keys.json

  ROOT_TOKEN=$(jq -r '.root_token' /opt/vault/keys.json)
fi

docker exec -i ${VAULT_CONTAINER_NAME} sh -c "vault login ${ROOT_TOKEN}"

docker exec ${VAULT_CONTAINER_NAME} sh -c 'vault secrets enable -path=secret -version=2 kv || true'

docker exec -i ${VAULT_CONTAINER_NAME} sh -c "vault kv put secret/keycloak admin_password=admin admin_user=admin"

echo "Vault initialization completed."
