#!/bin/bash
echo "Waiting for Keycloak to be ready..."

until curl -sf http://localhost:8080/realms/master > /dev/null; do
  sleep 5
done

echo "Disabling SSL Requirement in master realm..."

# Login to KC Admin CLI
/opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password admin

# Disable SSL enforcement in DB realm config
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE

echo "SSL disabled successfully."
