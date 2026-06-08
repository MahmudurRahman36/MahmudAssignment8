variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "mahmud-monitoring"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "key_name" {
  description = "AWS EC2 SSH Key Pair Name"
  type        = string
  default     = "ostad_batch_11_mahmud"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the monitoring server"
  type        = string
  default     = "0.0.0.0/0"
}
