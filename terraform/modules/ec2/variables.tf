variable "name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "role" {
  description = "Role tag (e.g. monitoring)"
  type        = string
  default     = "monitoring"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the existing EC2 key pair"
  type        = string
  default     = "ostad_batch_11_mahmud"
}

variable "user_data" {
  description = "User data script for bootstrapping the instance"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}
