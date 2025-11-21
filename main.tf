terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "template_file" "vault_hcl" {
  template = file("${path.module}/vault.hcl.tpl")
  vars = {
    region      = var.aws_region
    kms_key_arn = aws_kms_key.vault_unseal.arn
  }
}

resource "local_file" "vault_hcl_file" {
  content  = data.template_file.vault_hcl.rendered
  filename = "${path.module}/vault.hcl" # will be uploaded by provisioner
}

data "aws_caller_identity" "current" {}

# -------------------------
# AMI
# -------------------------
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "willcloud-ec2-sg"
  description = "Allow SSH + Keycloak + Vault"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# KMS Key for Vault Auto-Unseal
# -------------------------
resource "aws_kms_key" "vault_unseal" {
  description             = "Vault auto-unseal key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "vault_alias" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.vault_unseal.key_id
}

# -------------------------
# IAM Role for EC2
# -------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vault_role" {
  name               = "ec2-vault-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "vault_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt", "kms:Decrypt", "kms:DescribeKey",
      "kms:GenerateDataKey*", "kms:ReEncrypt*"
    ]
    resources = [aws_kms_key.vault_unseal.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "vault_policy" {
  name   = "ec2-vault-policy"
  policy = data.aws_iam_policy_document.vault_policy.json
}

resource "aws_iam_role_policy_attachment" "role_attach" {
  role       = aws_iam_role.vault_role.name
  policy_arn = aws_iam_policy.vault_policy.arn
}

resource "aws_iam_instance_profile" "vault_profile" {
  name = "vault-profile"
  role = aws_iam_role.vault_role.name
}

# -------------------------
# EC2 Instance
# -------------------------
resource "aws_instance" "app" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  security_groups      = [aws_security_group.ec2_sg.name]
  iam_instance_profile = aws_iam_instance_profile.vault_profile.name

  tags = {
    Name = "willcloud-ec2"
  }

  # uploads
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
    source      = "vault.hcl"
    destination = "/home/ec2-user/vault.hcl"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("willcloud-key.pem")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "vault-init.sh"
    destination = "/home/ec2-user/vault-init.sh"

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

  # run script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/docker.sh",
      "chmod +x /home/ec2-user/vault-init.sh",
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
