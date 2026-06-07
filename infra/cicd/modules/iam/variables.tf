variable "github_repo" {
  description = "GitHub repository allowed to assume the IAM Role"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM Role"
  type        = string
  default     = "github-actions-tf-role"
}
