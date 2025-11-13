provider "aws" {
  region            = "us-east-1"
  access_key        = "test"
  secret_key        = "test"
  s3_use_path_style = true

  endpoints {
    s3  = "http://localhost.localstack.cloud:4566"
    ec2 = "http://localhost.localstack.cloud:4566"
    iam = "http://localhost.localstack.cloud:4566"
  }
}
