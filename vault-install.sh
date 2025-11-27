#!/bin/bash
set -e

# Install Vault
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y vault

# Create config directory
mkdir -p /etc/vault
mkdir -p /opt/vault/data
sudo chown -R vault:vault /opt/vault

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
sudo systemctl enable vault
sudo systemctl start vault
