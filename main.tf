terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2"
    }
  }
}

data "aws_caller_identity" "current" {}

# -------------------------
# vault.hcl Template
# -------------------------
data "template_file" "vault_hcl" {
  template = file("${path.module}/vault.hcl.tpl")
  vars = {
    region      = var.aws_region
    kms_key_arn = local.kms_key_arn != "" ? local.kms_key_arn : ""
  }
}

resource "local_file" "vault_hcl_file" {
  content  = data.template_file.vault_hcl.rendered
  filename = "${path.module}/vault.hcl"
}

# -------------------------
# AMI (Amazon Linux 2)
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
data "aws_security_group" "existing_ec2_sg" {
  count = 1
  filter {
    name   = "group-name"
    values = [var.sg_name]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_security_group" "ec2_sg" {
  count       = length(try(data.aws_security_group.existing_ec2_sg[0].id, "")) == 0 ? 1 : 0
  name        = var.sg_name
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

# final SG id to use
locals {
  final_sg_id = length(try(data.aws_security_group.existing_ec2_sg[0].id, "")) > 0 ? data.aws_security_group.existing_ec2_sg[0].id : aws_security_group.ec2_sg[0].id
}

# -------------------------
# KMS key + alias: detect alias then create if missing
# -------------------------
data "aws_kms_alias" "existing_vault_alias" {
  count = 1
  name  = var.kms_key_alias
}

resource "aws_kms_key" "vault_unseal" {
  count                   = length(try(data.aws_kms_alias.existing_vault_alias[0].target_key_id, "")) == 0 ? 1 : 0
  description             = "Vault auto-unseal key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "vault_alias" {
  count         = length(try(data.aws_kms_alias.existing_vault_alias[0].target_key_id, "")) == 0 ? 1 : 0
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.vault_unseal[0].key_id
}

# final kms key arn
locals {
  kms_key_arn = length(try(data.aws_kms_alias.existing_vault_alias[0].target_key_arn, "")) > 0 ? data.aws_kms_alias.existing_vault_alias[0].target_key_arn : aws_kms_key.vault_unseal[0].arn
}

# -------------------------
# IAM Role / Policy / Instance Profile: detect existing then create if missing
# -------------------------
data "aws_iam_role" "existing_role" {
  count = 1
  name  = var.iam_role_name
}

data "aws_iam_policy" "existing_policy" {
  count = 1
  name  = var.iam_policy_name
}

data "aws_iam_instance_profile" "existing_profile" {
  count = 1
  name  = var.instance_profile_name
}

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
  count              = length(try(data.aws_iam_role.existing_role[0].arn, "")) == 0 ? 1 : 0
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  description        = "EC2 role for Vault auto-unseal and SecretsManager access"
}

data "aws_iam_policy_document" "vault_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt", "kms:Decrypt", "kms:DescribeKey",
      "kms:GenerateDataKey*", "kms:ReEncrypt*"
    ]
    resources = [local.kms_key_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:TagResource"
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.vault_secret_path}*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "vault_policy" {
  count  = length(try(data.aws_iam_policy.existing_policy[0].arn, "")) == 0 ? 1 : 0
  name   = var.iam_policy_name
  policy = data.aws_iam_policy_document.vault_policy.json
}

resource "aws_iam_role_policy_attachment" "role_attach" {
  count      = length(try(data.aws_iam_role.existing_role[0].arn, "")) == 0 ? 1 : 0
  role       = aws_iam_role.vault_role[0].name
  policy_arn = aws_iam_policy.vault_policy[0].arn
}

resource "aws_iam_instance_profile" "vault_profile" {
  count = length(try(data.aws_iam_instance_profile.existing_profile[0].arn, "")) == 0 ? 1 : 0
  name  = var.instance_profile_name
  role  = aws_iam_role.vault_role[0].name
}

# final instance profile name (for aws_instance.iam_instance_profile)
locals {
  final_instance_profile = (
    length(try(data.aws_iam_instance_profile.existing_profile[0].arn, "")) > 0
    ? data.aws_iam_instance_profile.existing_profile[0].name
    : aws_iam_instance_profile.vault_profile[0].name
  )
}

# final role arn/name
locals {
  final_role_name  = length(try(data.aws_iam_role.existing_role[0].arn, "")) > 0 ? data.aws_iam_role.existing_role[0].name : aws_iam_role.vault_role[0].name
  final_policy_arn = length(try(data.aws_iam_policy.existing_policy[0].arn, "")) > 0 ? data.aws_iam_policy.existing_policy[0].arn : aws_iam_policy.vault_policy[0].arn
  final_kms_arn    = local.kms_key_arn
}

# -------------------------
# EC2 Instance
# -------------------------
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [local.final_sg_id]
  iam_instance_profile   = local.final_instance_profile

  tags = {
    Name = var.instance_name
  }

  # user-data runs docker install + compose + keycloak + vault reliably
  user_data = file("${path.module}/user-data.sh")

  # Upload required application files
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

  provisioner "file" {
    source      = "vault-init.sh"
    destination = "/home/ec2-user/vault-init.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "disable-ssl.sh"
    destination = "/home/ec2-user/disable-ssl.sh"

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
