variable "aws_region" { type = string }
variable "project_name"  { type = string }
variable "vpc_id"        { type = string }
variable "subnet_ids"    { type = list(string) }
variable "max_agents"    { type = number }
variable "instance_type" { type = string }
variable "agent_image"   { type = string }
variable "artifacts_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket to store artifacts"
}
variable "artifacts_bucket_id" {
  type        = string
  description = "Name/ID of the artifacts bucket"
}
variable "asg_ready_timeout" {
  type        = number
  default     = 300
  description = "Seconds to wait for the ASG to report an InService instance"
}

variable "asg_poll_interval" {
  type        = number
  default     = 10
  description = "Seconds between ASG status polls in the scale-up Lambda"
}