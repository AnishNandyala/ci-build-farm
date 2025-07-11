variable "project_name"  { type = string }
variable "vpc_id"        { type = string }
variable "subnet_ids"    { type = list(string) }
variable "max_agents"    { type = number }
variable "instance_type" { type = string }
variable "agent_image"   { type = string }