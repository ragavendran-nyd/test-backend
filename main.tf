terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_instance" "example" {
  ami           = "ami-12345678" # Dummy AMI used only for LocalStack
  instance_type = "t2.micro"
}
