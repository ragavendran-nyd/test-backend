#!/bin/bash
set -e

# Install Vault
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y vault

# Create config directory
mkdir -p /etc/vault
mkdir -p /opt/vault/data
chown -R vault:vault /opt/vault

# Vault config
cat <<EOF >/etc/vault/config.hcl
ui = true
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}
storage "file" {
  path = "/opt/vault/data"
}
EOF

# Enable Vault as service
systemctl enable vault
systemctl start vault
