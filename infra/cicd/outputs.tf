output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "S3 Bucket name is used to store the state file."
}

output "cloudformation_artifact_bucket_name" {
  value       = aws_s3_bucket.cloudformation_artifacts.id
  description = "S3 Bucket name is used to store packaged CloudFormation nested templates."
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB Table name is used to store the lock file."
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Role ARN is used to configure into GitHub Actions."
}
