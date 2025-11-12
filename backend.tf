terraform {
  backend "s3" {
    bucket = "willcloud-devops-bucket-state"
    key    = "localstack/terraform.tfstate"
    region = "ap-southeast-1"

    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true

    endpoints = {
      s3 = "http://localhost.localstack.cloud:4566"
    }
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source  = "hashicorp/aws"
    }
  }
}
