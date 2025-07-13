output "queue_url" {
  description = "URL of the SQS queue for CI jobs"
  value       = aws_sqs_queue.job_queue.id
}

output "queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.job_queue.arn
}