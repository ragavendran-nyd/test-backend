terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_instance" "free_tier" {
  ami           = "ami-0c2b8ca1dad447f8a"
  instance_type = "t2.micro"
  key_name      = "willcloud-key-ec2"

  tags = {
    Name = "FreeTierEC2"
  }
}

output "instance_id" {
  value = aws_instance.free_tier.id
}
