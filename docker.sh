#!/bin/bash
set -e

yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Move compose file
mkdir -p /opt/app
mv /home/ec2-user/docker-compose.yml /opt/app/docker-compose.yml
cd /opt/app

# Start services
docker-compose up -d
