output "bucket_id" {
  description = "Name of the artifacts S3 bucket"
  value       = aws_s3_bucket.ci-build-farm-artifacts.id
}

output "bucket_arn" {
  description = "ARN of the artifacts bucket"
  value       = aws_s3_bucket.ci-build-farm-artifacts.arn
}