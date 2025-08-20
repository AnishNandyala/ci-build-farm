variable "aws_region" { type = string }
variable "project_name"  { type = string }
variable "scale_up_invoke_arn" { type = string }
variable "scale_up_function_name" { type = string }
variable "allowed_origins" {
  type    = list(string)
  default = ["http://localhost:3000"]
}