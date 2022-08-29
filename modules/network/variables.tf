variable "aws_availability_zone" { type = list(string) }
variable "env_prefix" { type = string }
variable "subnet_count" {
  type = number
  description = "Number of subnet for worker nodes"
  default = 2
}