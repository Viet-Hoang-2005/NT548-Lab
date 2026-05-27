<div align="center">

# BÀI TẬP THỰC HÀNH NT548

</div>

## Lab 1: Dùng Terraform và CloudFormation để quản lý và triển khai hạ tầng AWS

### 1. Các dịch vụ cần triển khai:

**1. VPC:** Tạo một VPC chứa các thành phần sau:

- Subnets: Bao gồm cả Public Subnet (kết nối với Internet Gateway) và Private Subnet (sử dụng NAT Gateway để kết nối ra ngoài).

- Internet Gateway: Kết nối với Public Subnet để cho phép các tài nguyên bên trong có thể truy cập Internet.

- Default Security Group: Tạo Security Group mặc định cho VPC

**2. Route Tables:** Tạo Route Tables cho Public và Private Subnet:

- Public Route Table: Định tuyến lưu lượng Internet thông qua Internet Gateway.

- Private Route Table: Định tuyến lưu lượng Internet thông qua NAT Gateway.

**3. NAT Gateway:** Cho phép các tài nguyên trong Private Subnet có thể kết nối Internet mà vẫn bảo đảm tính bảo mật.

**4. EC2:** Tạo các instance trong Public và Private Subnet, đảm bảo Public instance có thể truy cập từ Internet, còn Private instance chỉ có thể truy cập từ Public instance thông qua SSH hoặc các phương thức bảo mật khác.

**5. Security Groups:** Tạo các Security Groups để kiểm soát lưu lượng vào/ra của EC2 instances:

- Public EC2 Security Group: Chỉ cho phép kết nối SSH (port 22) từ một IP cụ thể (hoặc IP của người dùng).

- Private EC2 Security Group: Cho phép kết nối từ Public EC2 instance thông qua port cần thiết (SSH hoặc các port khác nếu có nhu cầu).

### 2. Yêu cầu:
- Các dịch vụ phải được viết dưới dạng module.

- Phải đảm bảo an toàn bảo mật cho EC2 (thiết lập Security Groups).

- Phải có các test cases để kiểm tra từng dịch vụ được triển khai thành công

## Lab 2: Quản lý và triển khai hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins

### 1. Triển khai hạ tầng AWS sử dụng Terraform và tự động hóa quy trình với GitHub Actions

- Dùng Terraform để triển khai các dịch vụ AWS bao gồm: VPC, Route Tables, NAT Gateway, EC2, Security Groups đã thực hiện ở bài tập 1.

- Tự động hóa quá trình triển khai với GitHub Actions.

- Tích hợp Checkov để kiểm tra tính tuân thủ và bảo mật của mã nguồn Terraform.

### 2. Triển khai hạ tầng AWS với CloudFormation và tự động hóa quy trình build và deploy với AWS CodePipeline

- Dùng CloudFormation để triển khai các dịch vụ AWS bao gồm: VPC, Route Tables, NAT Gateway, EC2, Security Groups đã thực hiện trong bài tập 1.

- Sử dụng AWS CodeBuild, tích hợp cfn-lint và Taskcat để kiểm tra tính đúng đắn của mã CloudFormation.

- Sử dụng AWS CodePipeline để tự động hóa quy trình build và deploy từ mã nguồn trên CodeCommit.

### 3. Sử dụng Jenkins (hoặc một dịch vụ tương tự) để quản lý quy trình CI/CD cho ứng dụng microservices

- Sử dụng Jenkins (hoặc một dịch vụ tương tự) để tự động hóa quá trình build, test và deploy ứng dụng microservices trên Docker, Kubernetes.

- Tích hợp SonarQube để kiểm tra chất lượng mã nguồn.

- Có thể tích hợp thêm các công cụ kiểm tra bảo mật như Snyk hoặc Trivy để tăng cường tính an toàn của mã nguồn (tùy chọn).