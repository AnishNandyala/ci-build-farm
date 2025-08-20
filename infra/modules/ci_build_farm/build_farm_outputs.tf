output "queue_url" {
  description = "URL of the SQS queue for CI jobs"
  value       = aws_sqs_queue.job_queue.id
}

output "queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.job_queue.arn
}

output "scale_down_sns_arn" {
    value = aws_sns_topic.scale_down.arn
}

output "scale_up_invoke_arn" {
  description = "Invoke ARN for the scale-up Lambda"
  value       = aws_lambda_function.scale_up.invoke_arn
}

output "scale_up_function_name" {
  description = "Name of the scale-up Lambda"
  value       = aws_lambda_function.scale_up.function_name
}