#!/bin/bash
set -e

echo "Installing Docker on Amazon Linux 2023..."

sudo yum update -y
sudo yum install -y docker

sudo systemctl enable docker
sudo systemctl start docker

echo "Docker installed:"
docker --version

### Install Docker Compose V2 ###
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true

echo "Docker Compose installed:"
sudo docker-compose --version


### Install jq and AWS CLI v2 (needed for vault-init) ###
sudo yum install -y jq
# Install AWS CLI v2 (curl download)
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
sudo unzip -o /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin

### Prepare application folder ###
sudo mkdir -p /opt/app
sudo mkdir -p /opt/vault

# Move files placed by Terraform
sudo mv /home/ec2-user/docker-compose.yml /opt/app/docker-compose.yml || true
sudo mv /home/ec2-user/disable-ssl.sh /opt/app/disable-ssl.sh || true
sudo mv /home/ec2-user/vault.hcl /opt/app/vault.hcl || true
sudo mv /home/ec2-user/vault-init.sh /opt/app/vault-init.sh || true

sudo chmod +x /opt/app/disable-ssl.sh || true
sudo chmod +x /opt/app/vault-init.sh || true

cd /opt/app

### Pull images first (avoids timeout) ###
sudo docker-compose pull || true

### Start stack ###
sudo docker-compose up -d

### Run vault-init script (it will detect initialized state) ###
if [ -f /opt/app/vault-init.sh ]; then
  sudo chmod +x /opt/app/vault-init.sh
  /opt/app/vault-init.sh
fi

echo "Docker stack started."
