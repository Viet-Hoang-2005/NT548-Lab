<div align="center">

# BÀI TẬP THỰC HÀNH NT548

</div>

## Tổng quan

Repository này chứa mã nguồn Infrastructure as Code dùng để quản lý và triển khai hạ tầng AWS bằng Terraform và CloudFormation. Dự án cũng có GitHub Actions để tự động kiểm tra, đóng gói và triển khai hạ tầng.

## Cấu trúc thư mục

```text
.
|-- .github/
|   |-- workflows/
|   |   |-- terraform-plan.yml
|   |   |-- terraform-apply.yml
|   |   |-- cloudformation-validate.yml
|   |   `-- cloudformation-deploy.yml
|   `-- WORKFLOWS.md
`-- infra/
    |-- cicd/
    |-- terraform/
    `-- cloudformation/
```

- `.github/workflows`: các workflow GitHub Actions cho Terraform và CloudFormation.
- `infra/cicd`: hạ tầng bootstrap cho CI/CD, gồm S3 bucket, DynamoDB lock table, GitHub OIDC Provider và IAM Role.
- `infra/terraform`: hạ tầng AWS chính được triển khai bằng Terraform.
- `infra/cloudformation`: hạ tầng AWS chính được triển khai bằng CloudFormation nested stacks.

## Lab 1: Terraform và CloudFormation cho hạ tầng AWS

### Dịch vụ cần triển khai

**1. VPC**

- Public Subnet kết nối Internet thông qua Internet Gateway.
- Private Subnet truy cập Internet ra ngoài thông qua NAT Gateway.
- Default Security Group của VPC.

**2. Route Tables**

- Public Route Table định tuyến `0.0.0.0/0` qua Internet Gateway.
- Private Route Table định tuyến `0.0.0.0/0` qua NAT Gateway.

**3. NAT Gateway**

- Cho phép tài nguyên trong Private Subnet truy cập Internet để cập nhật hệ thống hoặc tải gói cần thiết, nhưng không nhận truy cập trực tiếp từ Internet.

**4. EC2**

- Public EC2 instance nằm trong Public Subnet và có thể truy cập từ Internet qua SSH theo IP được cho phép.
- Private EC2 instances nằm trong Private Subnet và chỉ cho phép SSH từ Public EC2 instance.

**5. Security Groups**

- Public EC2 Security Group chỉ mở SSH port `22` từ IP/CIDR được chỉ định.
- Private EC2 Security Group chỉ mở SSH port `22` từ Security Group của Public EC2.

## Lab 2: Tự động hóa CI/CD

### Terraform với GitHub Actions

- Dùng Terraform để triển khai VPC, Route Tables, NAT Gateway, EC2, Security Groups và ALB.
- Tự động chạy `terraform validate`, Checkov và `terraform plan` khi tạo Pull Request.
- Tự động chạy `terraform apply` khi merge hoặc push vào nhánh `main`.

### CloudFormation với GitHub Actions

- Dùng CloudFormation nested stacks để triển khai VPC, Route Tables, NAT Gateway, EC2, Security Groups và ALB.
- Tự động chạy `cfn-lint` và `aws cloudformation validate-template` khi tạo Pull Request.
- Tự động chạy `aws cloudformation package` và `aws cloudformation deploy` khi merge hoặc push vào nhánh `main`.

## Yêu cầu chung

- AWS CLI đã cấu hình quyền truy cập phù hợp.
- Terraform đã được cài đặt nếu chạy phần Terraform.
- GitHub repository variables cần có:
  - `IAM_ROLE_ARN`
  - `ALLOWED_SSH_CIDR`
  - `CFN_ARTIFACT_BUCKET`

Chi tiết cách chạy từng phần nằm trong các README con:

- `infra/cicd/README.md`
- `infra/terraform/README.md`
- `infra/cloudformation/README.md`
