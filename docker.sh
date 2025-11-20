#!/bin/bash
set -e

### Update and install Docker ###
yum update -y
amazon-linux-extras install docker -y

systemctl start docker
systemctl enable docker

### Install Docker Compose v2 ###
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true

echo "Docker Compose installed:"
docker-compose --version

### Prepare application folder ###
mkdir -p /opt/app

# Move files placed by Terraform
mv /home/ec2-user/docker-compose.yml /opt/app/docker-compose.yml
mv /home/ec2-user/disable-ssl.sh /opt/app/disable-ssl.sh

chmod +x /opt/app/disable-ssl.sh

cd /opt/app

### Pull images first (avoids timeout) ###
docker-compose pull

### Start stack ###
docker-compose up -d

echo "Docker stack started."
