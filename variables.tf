variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "vpc_id" {
  type        = string
  description = "VPC id where EC2 and SG should exist"
  default     = "vpc-057a60bd04b062b86"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
  default     = "willcloud-key"
}

variable "private_key_path" {
  type        = string
  description = "Path to the private key file used by Terraform provisioner (in repo or secrets)"
  default     = "willcloud-key.pem"
}

variable "kms_key_alias" {
  type        = string
  description = "KMS alias to use/create for Vault auto-unseal"
  default     = "alias/vault-auto-unseal"
}

variable "vault_secret_path" {
  type        = string
  description = "Secrets Manager path to store Vault init JSON"
  default     = "willcloud/vault/init"
}

variable "allowed_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# names used for detection/creation
variable "sg_name" {
  type    = string
  default = "willcloud-ec2-sg"
}

variable "instance_name" {
  type    = string
  default = "willcloud-ec2-keycloak-vault"
}

variable "iam_role_name" {
  type    = string
  default = "ec2-vault-role"
}

variable "iam_policy_name" {
  type    = string
  default = "ec2-vault-policy"
}

variable "instance_profile_name" {
  type    = string
  default = "vault-profile"
}
