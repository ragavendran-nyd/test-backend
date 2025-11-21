variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "vpc_id" {
  type    = string
  default = "vpc-057a60bd04b062b86"
}

variable "key_name" {
  type    = string
  default = "willcloud-key"
}


variable "kms_key_alias" {
  type    = string
  default = "alias/vault-auto-unseal"
}

variable "vault_secret_path" {
  type    = string
  default = "willcloud/vault/init"
}

variable "allowed_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
