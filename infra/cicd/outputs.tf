output "s3_bucket" {
  value       = module.s3.bucket_name
  description = "S3 Bucket Name for Terraform State"
}

output "cloudformation_artifact_bucket_name" {
  value       = aws_s3_bucket.cloudformation_artifacts.id
  description = "S3 Bucket name is used to store packaged CloudFormation nested templates."
}

output "dynamodb_table" {
  value       = module.dynamodb.table_name
  description = "DynamoDB Table Name for State Locking"
}

output "github_actions_role_arn" {
  value       = module.iam.role_arn
  description = "IAM Role ARN for GitHub Actions"
}
