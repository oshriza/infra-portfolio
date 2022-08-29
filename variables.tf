variable "region" {
  type        = string
  default     = "us-east-2"
  description = "region"
}
variable "aws_availability_zone" { type = list(string) }
variable "env_prefix" { type = string }
variable "argocd_ssh_location" { 
  type = string
  default = "~/.ssh/argocd"
}