#!/bin/bash
echo "Waiting for Keycloak to become ready..."

# Try admin login until it succeeds
until /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password admin > /dev/null 2>&1; do
    sleep 5
done

echo "Keycloak is ready. Disabling SSL requirement..."

# Set sslRequired to NONE
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE

echo "SSL requirement disabled successfully."