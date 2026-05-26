variable "public_subnet_id" {
  description = "Public subnet ID"
  type        = string
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

variable "instance_type" {
  description = "Instance type"
  type        = string
}
