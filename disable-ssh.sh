#!/bin/bash

# Wait until Keycloak API is available
echo "Waiting for Keycloak to be ready..."
until curl -sf http://localhost:8080/realms/master >/dev/null 2>&1; do
  sleep 5
done

echo "Keycloak is up. Disabling SSL requirement in master realm..."

# Login to admin CLI
/opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password admin

# Disable SSL enforcement
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE

echo "SSL requirement disabled successfully."
