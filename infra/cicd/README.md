# Hạ tầng Khởi tạo (Bootstrap Infrastructure)

Thư mục `infra/cicd` này chứa mã nguồn Terraform dùng để **khởi tạo** cho quy trình CI/CD và quản lý trạng thái (State Management).

## Các tài nguyên được tạo ra

Khi chạy Terraform trong thư mục này, các tài nguyên sau sẽ được sinh ra trên AWS:
1. **S3 Bucket (`group7-tfstate-artifact`)**: Dùng để lưu trữ an toàn file trạng thái (`terraform.tfstate`) của hạ tầng chính.

2. **DynamoDB Table (`group7-tfstate-locks`)**: Dùng để khóa (Lock) file trạng thái mỗi khi có tiến trình đang ghi, tránh đụng độ (Race condition) giữa các luồng CI/CD.

3. **GitHub OIDC Provider**: Thiết lập mối quan hệ tin cậy (Trust relationship) giữa AWS và GitHub Actions.

4. **IAM Role (`github-actions-tf-role`)**: Vai trò (Role) đặc biệt được cấp quyền (mặc định là AdministratorAccess để phục vụ lab) mà GitHub Actions sẽ mượn tạm để chạy lệnh triển khai hạ tầng.
