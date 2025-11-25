terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ----------------------------------------
# AMI Lookup
# ----------------------------------------
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ----------------------------------------
# Detect existing SG
# ----------------------------------------
data "aws_security_group" "existing" {
  filter {
    name   = "group-name"
    values = ["willcloud-ec2-sg"]
  }

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# ----------------------------------------
# Create SG only if not already present
# ----------------------------------------
resource "aws_security_group" "willcloud_ec2_sg" {
  count = data.aws_security_group.existing.id != "" ? 0 : 1

  name   = "willcloud-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8200
    to_port     = 8200
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

# ----------------------------------------
# Correct Working Locals Block
# ----------------------------------------
locals {
  sg_id = (
    data.aws_security_group.existing.id != "" ?
    data.aws_security_group.existing.id :
    aws_security_group.willcloud_ec2_sg[0].id
  )
}

# ----------------------------------------
# EC2 instance
# ----------------------------------------
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [local.sg_id]

  tags = {
    Name = "willcloud-ec2-vault"
  }

  # Upload docker.sh
  provisioner "file" {
    source      = "docker.sh"
    destination = "/home/ec2-user/docker.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Upload docker-compose.yml
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ec2-user/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Upload vault.hcl
  provisioner "file" {
    source      = "vault.hcl"
    destination = "/home/ec2-user/vault.hcl"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Execute script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/docker.sh",
      "sudo /home/ec2-user/docker.sh /home/ec2-user/docker-compose.yml /home/ec2-user/vault.hcl"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

output "ec2_ip" {
  value = aws_instance.app.public_ip
}
