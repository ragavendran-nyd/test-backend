resource "aws_s3_bucket" "backend_bucket" {
  bucket = "willcloud-backend-s3"
}

output "bucket_name" {
  value = aws_s3_bucket.backend_bucket.bucket
}
