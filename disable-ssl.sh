#!/bin/bash
set -e

# expects KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD to be available in environment
SERVER_URL="http://localhost:8080"

# try login until succeeds
until /opt/keycloak/bin/kcadm.sh config credentials --server ${SERVER_URL} --realm master --user ${KEYCLOAK_ADMIN} --password ${KEYCLOAK_ADMIN_PASSWORD} >/dev/null 2>&1; do
  sleep 2
done

# set sslRequired to NONE
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE || true

echo "sslRequired set to NONE"