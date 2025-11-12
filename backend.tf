terraform {
  backend "s3" {
    bucket                      = "terraform-backend-localstack"
    key                         = "state/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    force_path_style            = true
    endpoints = {
      s3 = "http://localhost.localstack.cloud:4566"
    }
  }
}
