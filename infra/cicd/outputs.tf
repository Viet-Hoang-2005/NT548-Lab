output "s3_bucket" {
  value       = module.s3.bucket_name
  description = "S3 Bucket Name for Terraform State"
}

output "dynamodb_table" {
  value       = module.dynamodb.table_name
  description = "DynamoDB Table Name for State Locking"
}

output "github_actions_role_arn" {
  value       = module.iam.role_arn
  description = "IAM Role ARN for GitHub Actions"
}
