terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-basic-sg"
  description = "Allow SSH"
  vpc_id      = "vpc-057a60bd04b062b86"

  ingress {
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

resource "aws_instance" "app" {
  ami           = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 (Sydney)
  instance_type = "t2.micro"
  key_name      = "cloudwill-key-ec2"

  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = "cloudwill-ec2"
  }
}

output "ec2_ip" {
  value = aws_instance.app.public_ip
}
