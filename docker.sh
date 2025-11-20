#!/bin/bash
set -e

yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Install Docker Compose v2 (correct for Amazon Linux 2)
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

# Add symlink so Terraform remote-exec can find it in PATH
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true

# Validate install
docker-compose --version

# Prepare app directory
mkdir -p /opt/app
mv /home/ec2-user/docker-compose.yml /opt/app/docker-compose.yml
mv /home/ec2-user/disable-ssh.sh /opt/app/disable-ssh.sh
cd /opt/app

# Start containers
docker-compose up -d
