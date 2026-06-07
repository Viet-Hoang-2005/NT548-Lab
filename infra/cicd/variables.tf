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

variable "terraform_state_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "group7-tfstate-artifact"
}

variable "cloudformation_artifact_bucket_name" {
  description = "S3 bucket name for CloudFormation packaged nested templates"
  type        = string
  default     = "group7-cfn-artifacts"
}
