# Hạ tầng bootstrap cho CI/CD

Thư mục `infra/cicd` dùng Terraform để tạo các tài nguyên nền tảng cho GitHub Actions CI/CD.

Stack này không tạo hạ tầng ứng dụng chính như VPC, EC2 hay ALB. Nó tạo các thành phần dùng chung để pipeline Terraform và CloudFormation có thể chạy an toàn.

## Tài nguyên được tạo

1. `group7-tfstate-artifact`
   S3 bucket lưu remote state của Terraform. Bucket bật versioning, server-side encryption và chặn public access.

2. `group7-tfstate-locks`
   DynamoDB table dùng cho Terraform state locking, tránh nhiều pipeline ghi state cùng lúc.

3. `group7-cfn-artifacts`
   S3 bucket lưu packaged CloudFormation nested templates khi workflow chạy `aws cloudformation package`. Bucket bật versioning, server-side encryption và chặn public access.

4. GitHub OIDC Provider
   Thiết lập trust relationship giữa AWS và GitHub Actions.

5. `github-actions-tf-role`
   IAM Role cho GitHub Actions assume bằng OIDC. Role đang gắn `AdministratorAccess` để phục vụ bài lab.

## Cách chạy

```bash
cd infra/cicd
terraform init
terraform plan
terraform apply
```

## Outputs cần dùng

Sau khi apply, lấy outputs:

```bash
terraform output
```

Gán các giá trị vào GitHub repository variables:

- `github_actions_role_arn` -> `IAM_ROLE_ARN`
- `cloudformation_artifact_bucket_name` -> `CFN_ARTIFACT_BUCKET`

Ngoài ra cần tự cấu hình:

- `ALLOWED_SSH_CIDR`: IP/CIDR được phép SSH vào public EC2, ví dụ `203.0.113.10/32`.

## Lưu ý

S3 bucket name là global unique trên AWS. Nếu tên mặc định đã bị trùng, đổi giá trị trong `variables.tf` hoặc truyền bằng `terraform.tfvars`.
