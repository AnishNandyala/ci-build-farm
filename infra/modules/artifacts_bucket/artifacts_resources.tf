resource "aws_s3_bucket" "ci-build-farm-artifacts" {
  bucket = "${var.project_name}-artifacts"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.ci-build-farm-artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}