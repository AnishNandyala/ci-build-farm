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