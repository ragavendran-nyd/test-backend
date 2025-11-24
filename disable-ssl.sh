#!/usr/bin/env bash
set -e
# intended to run inside a Keycloak image (or be executed from keycloak-fix)
SERVER="http://keycloak:8080"
echo "waiting for Keycloak admin endpoint..."
until curl -sSf "${SERVER}/realms/master" >/dev/null 2>&1; do sleep 2; done
/opt/keycloak/bin/kcadm.sh config credentials --server "${SERVER}" --realm master --user "${KEYCLOAK_ADMIN:-admin}" --password "${KEYCLOAK_ADMIN_PASSWORD:-admin}"
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE || true
echo "sslRequired disabled"