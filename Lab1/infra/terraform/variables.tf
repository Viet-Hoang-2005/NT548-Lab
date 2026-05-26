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
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
