resource "aws_iam_policy" "tf_state_access" {
  name        = "TerraformStateAccess"
  description = "Allow Terraform to read/write its S3 backend state"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::ci-build-farm-tfstate-bucket"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": [
        "arn:aws:s3:::ci-build-farm-tfstate-bucket/ci-build-farm/terraform.tfstate"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": [
        "arn:aws:s3:::ci-build-farm-tfstate-bucket/ci-build-farm/terraform.tfstate.tflock"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_user_policy_attachment" "attach_tf_state" {
  user       = "anish_n" # or your CI role
  policy_arn = aws_iam_policy.tf_state_access.arn
}