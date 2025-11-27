terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ------------------------------
# AMI lookup
# ------------------------------
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ------------------------------
# Try to find existing SG
# ------------------------------
data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["willcloud-ec2-sg"]
  }

  filter {
    name   = "vpc-id"
    values = ["vpc-057a60bd04b062b86"]
  }
}

# ------------------------------
# Create SG if not exists
# ------------------------------
resource "aws_security_group" "ec2_sg" {
  count       = data.aws_security_group.existing_sg.id != "" ? 0 : 1
  name        = "willcloud-ec2-sg"
  description = "Allow SSH only"
  vpc_id      = "vpc-057a60bd04b062b86"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  final_sg_id = (
    data.aws_security_group.existing_sg.id != "" ?
    data.aws_security_group.existing_sg.id :
    aws_security_group.ec2_sg[0].id
  )
}

# ------------------------------
# EC2 instance (clean)
# ------------------------------
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  key_name      = "willcloud-key"

  vpc_security_group_ids = [local.final_sg_id]

  tags = {
    Name = "willcloud-ec2"
  }

  provisioner "file" {
    source      = "docker.sh"
    destination = "/home/ec2-user/docker.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("willcloud-key.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/docker.sh",
      "sudo /home/ec2-user/docker.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("willcloud-key.pem")
      host        = self.public_ip
    }
  }
}

output "ec2_ip" {
  value = aws_instance.app.public_ip
}

# ------------------------------
# AWS Cognito (new)
# ------------------------------

resource "aws_cognito_user_pool" "main" {
  name = "willcloud-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "client" {
  name            = "willcloud-client"
  user_pool_id    = aws_cognito_user_pool.main.id
  generate_secret = false

  callback_urls = [
    "http://localhost:3000/callback",
    "https://example.com"
  ]

  logout_urls = [
    "http://localhost:3000/callback",
    "https://example.com/logout"
  ]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "willcloud-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Allocate a static Elastic IP and attach to the EC2 instance
resource "aws_eip" "static_ip" {
  instance = aws_instance.app.id
  domain   = "vpc"
}

