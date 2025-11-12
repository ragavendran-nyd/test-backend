terraform {
  backend "s3" {
    bucket                      = "terraform-backend-localstack"
    key                         = "state/terraform.tfstate"
    region                      = "us-east-1"
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    endpoints = {
      s3 = "http://localhost.localstack.cloud:4566"
    }
  }
}
