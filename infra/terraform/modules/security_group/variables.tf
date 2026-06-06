variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ssh_ip" {
  description = "IP address allowed to SSH into Public SG"
  type        = string
}
