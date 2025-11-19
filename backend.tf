terraform {
  backend "s3" {
    bucket         = "willcloud-tf-state-bucket"
    key            = "state/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "willcloud-terraform-lock-table"
    encrypt        = true
  }
}
