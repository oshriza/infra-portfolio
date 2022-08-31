variable "region" {
  type        = string
  default     = "us-east-2"
  description = "region"
}
variable "env_prefix" { type = string }
variable "argocd_ssh_location" { 
  type = string
  default = "~/.ssh/argocd"
}
variable "vpc_cidr" { type = string }
variable "vpc_prefix" { type = number }