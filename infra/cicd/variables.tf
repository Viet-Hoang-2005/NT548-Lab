variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the IAM Role"
  type        = string
  default     = "Viet-Hoang-2005/NT548-Lab"
}
