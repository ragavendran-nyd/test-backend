#!/bin/bash
set -e

COMPOSE_SRC="$1"
VAULT_HCL_SRC="$2"

# Install docker
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo systemctl start docker
sudo systemctl enable docker

# Install docker-compose v2 binary
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose || true

# Prepare app folder
sudo mkdir -p /opt/app
sudo chown ec2-user:ec2-user /opt/app

# Move compose and vault.hcl
sudo mv "$COMPOSE_SRC" /opt/app/docker-compose.yml
sudo mv "$VAULT_HCL_SRC" /opt/app/vault.hcl
sudo chmod 644 /opt/app/vault.hcl


mkdir -p /opt/vault/data
sudo mv /home/ec2-user/vault.hcl /opt/vault/vault.hcl
sudo mv /home/ec2-user/docker-compose.yml /opt/app/docker-compose.yml

cd /opt/app
docker compose down || true
docker compose up -d

# Wait for vault container to exist
sleep 3

# If vault container is running or restarting, inject vault.hcl into the named volume path inside container
if sudo docker ps -a --format "{{.Names}}" | grep -q "vault"; then
  # Start a temporary dev server if vault exits immediately, to allow writing the file
  # If vault is already up with config mounted, skip
  if ! sudo docker exec vault test -f /vault/vault.hcl >/dev/null 2>&1; then
    # Start a temporary vault in dev mode to allow file copy
    sudo docker rm -f vault >/dev/null 2>&1 || true
    sudo docker run -d --name vault -p 8200:8200 -v vaultdata:/vault --cap-add=IPC_LOCK hashicorp/vault:1.16 server -dev
    sleep 2
    # Copy the vault.hcl into the named volume inside the running container
    sudo docker exec -i vault sh -c 'cat > /vault/vault.hcl' < /opt/app/vault.hcl
    # Restart compose normally
    sudo docker rm -f vault >/dev/null 2>&1 || true
    /usr/bin/docker-compose up -d
  fi
fi

# Done
exit 0