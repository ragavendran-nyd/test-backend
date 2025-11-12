resource "aws_s3_bucket" "demo_bucket" {
  bucket = "willcloud-localstack-test-s3"
}

output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.bucket
}
