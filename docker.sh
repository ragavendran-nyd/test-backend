#!/bin/bash
set -e

yum update -y
amazon-linux-extras install docker -y

systemctl enable docker
systemctl start docker

echo "Docker installed & running."
