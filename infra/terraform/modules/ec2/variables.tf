variable "public_subnet_ids" {
  description = "List of Public subnet IDs"
  type        = list(string)
}

variable "private_subnet_id" {
  description = "Private subnet ID"
  type        = string
}

variable "public_sg_id" {
  description = "Public security group ID"
  type        = string
}

variable "private_sg_id" {
  description = "Private security group ID"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for Master Node"
  type        = string
}

variable "worker_instance_type" {
  description = "Instance type for Worker Nodes"
  type        = string
}

variable "ami_name_filter" {
  description = "The name filter for the EC2 AMI"
  type        = string
}

variable "ami_owners" {
  description = "The owner ID for the EC2 AMI"
  type        = list(string)
}
