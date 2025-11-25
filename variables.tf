variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type    = string
  default = "willcloud-key"
}

variable "private_key_path" {
  type    = string
  default = "willcloud-key.pem"
}

variable "vpc_id" {
  type    = string
  default = "vpc-057a60bd04b062b86"
}
