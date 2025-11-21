#!/bin/bash
set -e

export AWS_REGION="ap-southeast-2"
VAULT_CONTAINER_NAME="vault"
SECRETS_MANAGER_NAME="willcloud/vault/init"

# wait for vault to be listening
echo "Waiting for Vault to be responsive..."
until docker exec ${VAULT_CONTAINER_NAME} /bin/sh -c 'curl -sS http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1'; do
  sleep 3
done

# check if initialized
INIT_STATUS=$(docker exec ${VAULT_CONTAINER_NAME} /bin/sh -c 'curl -sS http://127.0.0.1:8200/v1/sys/health' | jq -r '.initialized')

if [ "${INIT_STATUS}" = "false" ]; then
  echo "Initializing Vault..."
  docker exec ${VAULT_CONTAINER_NAME} /bin/sh -c 'vault operator init -format=json' > /opt/vault/keys.json

  # push keys.json to secrets manager
  aws secretsmanager create-secret --name "${SECRETS_MANAGER_NAME}" --description "Vault init data" --secret-string file:///opt/vault/keys.json --region ${AWS_REGION} || \
  aws secretsmanager put-secret-value --secret-id "${SECRETS_MANAGER_NAME}" --secret-string file:///opt/vault/keys.json --region ${AWS_REGION}

  # extract root token
  ROOT_TOKEN=$(jq -r '.root_token' /opt/vault/keys.json)

  echo "Vault initialized. Root token saved to Secrets Manager."
else
  echo "Vault is already initialized."
  # try to read existing secret if present
  if aws secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_NAME}" --region ${AWS_REGION} >/dev/null 2>&1; then
    aws secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_NAME}" --region ${AWS_REGION} --query SecretString --output text > /opt/vault/keys.json
    ROOT_TOKEN=$(jq -r '.root_token' /opt/vault/keys.json)
  else
    echo "No secret found; please initialize Vault manually or check logs."
    exit 1
  fi
fi

# Login to Vault using root token and enable KV v2 and write Keycloak secret
echo "Configuring Vault KV and seeding Keycloak secret..."
docker exec -i ${VAULT_CONTAINER_NAME} /bin/sh -c "vault login ${ROOT_TOKEN} >/dev/null 2>&1"

# enable kv-v2 at path secret/ if not present
if ! docker exec ${VAULT_CONTAINER_NAME} /bin/sh -c 'vault secrets list -format=json' | jq -e 'has("secret/")' >/dev/null 2>&1; then
  docker exec ${VAULT_CONTAINER_NAME} /bin/sh -c 'vault secrets enable -path=secret -version=2 kv'
fi

# Put Keycloak admin secret (replace values if needed)
cat > /tmp/keycloak_secret.json <<EOF
{
  "data": {
    "KEYCLOAK_ADMIN": "admin",
    "KEYCLOAK_ADMIN_PASSWORD": "admin"
  }
}
EOF

# write secret using vault CLI
docker exec -i ${VAULT_CONTAINER_NAME} /bin/sh -c "vault kv put secret/keycloak admin_password=admin admin_user=admin"

echo "Vault configured and Keycloak secret written to secret/keycloak."
