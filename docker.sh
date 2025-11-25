#!/bin/bash

COMPOSE_FILE=$1
VAULT_FILE=$2

echo "🚀 Installing Docker Compose"
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "📁 Creating application directory"
sudo mkdir -p /opt/app/vault
sudo cp $VAULT_FILE /opt/app/vault/vault.hcl

echo "📦 Starting containers"
sudo docker-compose -f $COMPOSE_FILE up -d

echo "⏳ Waiting for services to stabilize..."
sleep 10

echo "🔥 DONE — Docker stack deployed"
