output "ci_build_queue_url" {
  description = "CI build farm queue URL"
  value       = module.ci_build_farm.queue_url
}

output "ci_build_queue_arn" {
  description = "CI build farm queue ARN"
  value       = module.ci_build_farm.queue_arn
}

output "artifacts_bucket_id" {
  description = "Artifacts bucket name"
  value       = module.ci_build_artifacts.bucket_id
}

output "artifacts_bucket_arn" {
  description = "Artifacts bucket ARN"
  value       = module.ci_build_artifacts.bucket_arn
}