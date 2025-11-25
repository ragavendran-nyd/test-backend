#!/bin/bash
set -eux

# Log everything
exec > /var/log/userdata.log 2>&1

echo "### Updating system ###"
yum update -y

echo "### Installing Docker ###"
yum install -y docker

systemctl enable docker
systemctl start docker

echo "### Installing Docker Compose ###"
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "### Preparing app directory ###"
mkdir -p /opt/app
cd /opt/app

# Copy files that Terraform uploaded into EC2 user home
cp /home/ec2-user/docker-compose.yml .
cp /home/ec2-user/disable-ssl.sh .
cp /home/ec2-user/vault.hcl .
cp /home/ec2-user/vault-init.sh .

chmod +x disable-ssl.sh vault-init.sh

echo "### Starting docker-compose ###"
docker-compose pull
docker-compose up -d

echo "### Waiting for Vault to become healthy ###"
until [ "$(docker inspect -f {{.State.Health.Status}} vault)" = "healthy" ]; do
    echo "Vault not healthy yet... waiting"
    sleep 3
done

echo "### Running Vault init (safe) ###"
./vault-init.sh || true

echo "### DONE ###"
