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

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t3.small"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ami_name_filter" {
  description = "The name filter for the EC2 AMI"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ami_owners" {
  description = "The owner ID for the EC2 AMI"
  type        = list(string)
  default     = ["099720109477"]
}
