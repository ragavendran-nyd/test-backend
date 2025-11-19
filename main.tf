terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "willcloud-ec2-sg"
  description = "Allow SSH"
  vpc_id      = "vpc-057a60bd04b062b86"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Keycloak HTTP
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Keycloak HTTPS (optional)
  ingress {
    from_port   = 8443
    to_port     = 8443
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

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  key_name      = "willcloud-key"

  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = "willcloud-ec2"
  }

  # ---------------------------
  # Upload docker provisioning files
  # ---------------------------
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

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ec2-user/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("willcloud-key.pem")
      host        = self.public_ip
    }
  }

  # ---------------------------
  # Run installation script
  # ---------------------------
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
