variable "aws_region" { type = string }
variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "max_agents" {
  type    = number
  default = 2
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "agent_image" { type = string }