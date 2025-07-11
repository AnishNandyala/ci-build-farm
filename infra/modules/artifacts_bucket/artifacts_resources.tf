resource "aws_s3_bucket" "ci-build-farm-artifacts" {
  bucket = "${var.project_name}-artifacts"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}