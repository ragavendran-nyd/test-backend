#!/bin/bash
set -e

# Install Docker properly on Amazon Linux 2023
sudo yum update -y
sudo yum install -y docker

sudo systemctl enable docker
sudo systemctl start docker

### Install Docker Compose v2 ###
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true

echo "Docker Compose installed:"
docker-compose --version

### Install jq and AWS CLI v2 (needed for vault-init) ###
yum install -y jq
# Install AWS CLI v2 (curl download)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin

### Prepare application folder ###
mkdir -p /opt/app
mkdir -p /opt/vault

# Move files placed by Terraform
mv /home/ec2-user/docker-compose.yml /opt/app/docker-compose.yml || true
mv /home/ec2-user/disable-ssl.sh /opt/app/disable-ssl.sh || true
mv /home/ec2-user/vault.hcl /opt/app/vault.hcl || true
mv /home/ec2-user/vault-init.sh /opt/app/vault-init.sh || true

chmod +x /opt/app/disable-ssl.sh || true
chmod +x /opt/app/vault-init.sh || true

cd /opt/app

### Pull images first (avoids timeout) ###
docker-compose pull || true

### Start stack ###
docker-compose up -d

### Run vault-init script (it will detect initialized state) ###
if [ -f /opt/app/vault-init.sh ]; then
  chmod +x /opt/app/vault-init.sh
  /opt/app/vault-init.sh
fi

echo "Docker stack started."
