variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "allowed_ssh_ip" {
  description = "IP address allowed to SSH into Master Node"
  type        = string
  default     = "0.0.0.0/0"
}

variable "master_instance_type" {
  description = "EC2 Instance type for Master Node"
  type        = string
  default     = "t2.small"
}

variable "worker_instance_type" {
  description = "EC2 Instance type for Worker Nodes"
  type        = string
  default     = "t2.large"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
