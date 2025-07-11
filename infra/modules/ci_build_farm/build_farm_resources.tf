resource "aws_sqs_queue" "jobs" {
  name = "${var.project_name}-jobs"
}

