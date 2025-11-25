#!/bin/bash
set -e

sudo yum update -y
sudo yum install -y docker

sudo systemctl enable docker
sudo systemctl start docker

# Install docker-compose v2
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Docker + Compose installed."

# Create app directory
sudo mkdir -p /opt/app/vault

# Move vault config
sudo mv /home/ec2-user/vault.hcl /opt/app/vault/vault.hcl

# Move compose file
sudo mv /home/ec2-user/docker-compose.yml /opt/app/docker-compose.yml

cd /opt/app

echo "Starting containers..."
sudo docker-compose up -d

echo "DONE!"
