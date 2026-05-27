# GitHub Actions CI/CD cho Terraform

Thư mục workflow chứa các tệp cấu hình quy trình CI/CD chạy trên nền tảng GitHub Actions để tự động hóa việc kiểm thử và triển khai hạ tầng AWS bằng Terraform.

**Lưu ý:** Sử dụng cơ chế **AWS OIDC (OpenID Connect)** để xác thực (không cần lưu trữ `AWS_ACCESS_KEY_ID` và `AWS_SECRET_ACCESS_KEY` trên GitHub).

## 1. Workflow: Terraform Plan (`terraform-plan.yml`)

**Mục đích:** Kiểm tra lỗi cú pháp, quét lỗ hổng bảo mật và xem trước các thay đổi hạ tầng (báo giá thay đổi) trước khi hợp nhất (merge) mã nguồn.

**Kích hoạt khi:** Có sự kiện tạo mới hoặc cập nhật **Pull Request (PR)** vào nhánh `main` VÀ có thay đổi file bên trong thư mục `infra/terraform/`.

**Luồng hoạt động:**

1. **Checkout Code:** Kéo mã nguồn về máy ảo Ubuntu.

2. **AWS OIDC Auth:** Xin AWS cấp quyền truy cập tạm thời (Dựa vào `IAM_ROLE_ARN` cấu hình sẵn).

3. **Terraform Init & Validate:** Kết nối Backend (S3 + DynamoDB) và kiểm tra tính hợp lệ của mã nguồn.

4. **Checkov Security Scan:** Quét toàn bộ mã Terraform để tìm các rủi ro bảo mật (như mở nhầm port, thiếu mã hóa).

5. **Terraform Plan:** So sánh code hiện tại với hạ tầng thực tế trên AWS và kết xuất ra bản phác thảo thay đổi.

6. **Comment PR:** Bot của GitHub Actions sẽ tự động chèn kết quả của Plan và Checkov thành một bình luận (comment) ngay trong Pull Request.

7. **Gatekeeper:** Nếu bước Plan lỗi hoặc Checkov phát hiện rủi ro, Workflow sẽ kết thúc với tín hiệu lỗi (`exit 1`) để báo động người dùng không được Merge.

## 2. Workflow: Terraform Apply (`terraform-apply.yml`)

**Mục đích:** Chính thức triển khai và áp dụng (apply) các thay đổi mã nguồn lên hạ tầng AWS thực tế (mang gạch vữa đi xây).

**Kích hoạt khi:** Có sự kiện **Push trực tiếp** hoặc **Merge (gộp) Pull Request** vào nhánh `main` VÀ có thay đổi file bên trong thư mục `infra/terraform/`.

**Luồng hoạt động:**

1. **Checkout Code:** Kéo mã nguồn chuẩn nhất từ nhánh `main`.

2. **AWS OIDC Auth:** Xin quyền AWS.

3. **Terraform Init:** Kết nối S3 để đọc State, đồng thời sử dụng DynamoDB để **khóa (Lock)** file State lại, không cho tiến trình khác tranh giành.

4. **Terraform Apply:** Chạy lệnh `terraform apply -auto-approve`. Cờ `-auto-approve` đóng vai trò thay thế câu trả lời "yes" tự động. Máy ảo sẽ gửi các API Requests lên AWS để chính thức **tạo, sửa, hoặc xóa** tài nguyên. Cuối cùng cập nhật lại file `terraform.tfstate` trên S3.
