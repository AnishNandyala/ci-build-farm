variable "aws_region" { type = string }
variable "project_name" { type = string }
variable "max_agents" {
  type    = number
  default = 2
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "agent_image" { type = string }
variable "artifacts_bucket_id" {
  type        = string
  description = "Name of the S3 bucket for artifacts"
}
variable "asg_ready_timeout" {
  type    = number
  default = 300
}
variable "asg_poll_interval" {
  type    = number
  default = 10
}
variable "portal_allowed_origins" {
  type    = list(string)
  default = ["http://localhost:3000"] # dev default; override per env in terraform.tfvars
  description = "Allowed CORS origins for the portal frontend"
}