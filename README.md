# Bài tập thực hành NT548

Repo này chứa phần triển khai hạ tầng AWS và CI/CD cho Lab 1, Lab 2.

## Lab 1

Triển khai hạ tầng AWS bằng Terraform và CloudFormation:

- VPC gồm public subnet, private subnet, Internet Gateway và NAT Gateway.
- Route table public/private.
- EC2 public/private.
- Security Group kiểm soát SSH và luồng nội bộ.
- Test case kiểm tra từng thành phần hạ tầng.

## Lab 2

### Câu 1 - Terraform và GitHub Actions

Terraform triển khai lại các thành phần hạ tầng của Lab 1 và tích hợp GitHub Actions, Checkov để kiểm tra mã Terraform.

Tài liệu:

- `infra/terraform/README.md`

### Câu 2 - CloudFormation, CodeBuild, Taskcat và CodePipeline

CloudFormation triển khai VPC, route table, NAT Gateway, EC2, Security Group, ALB và cụm k3s. CodePipeline lấy source từ CodeCommit, CodeBuild chạy `cfn-lint`, `taskcat`, package template và deploy stack hạ tầng.

Tài liệu:

- `infra/cloudformation/README.md`

### Câu 3 - CI/CD microservices bằng GitHub Actions

Sử dụng GitHub Actions như dịch vụ tương tự Jenkins để build, test, scan và deploy microservices lên k3s. Phần này tái sử dụng 3 service SageLMS:

- `services/gateway`
- `services/auth-service`
- `services/course-service`

Pipeline tích hợp:

- Maven unit test.
- SonarQube hoặc SonarCloud nếu có `SONAR_TOKEN`.
- Docker build và push image lên GHCR.
- Trivy scan image.
- Deploy lên k3s qua self-hosted runner trên EC2 master.

Tài liệu:

- `docs/lab2-cau3-microservices-cicd.md`
