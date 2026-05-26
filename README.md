<div align="center">

# BÀI TẬP THỰC HÀNH NT548

</div>

## Lab 1: Dùng Terraform và CloudFormation để quản lý và triển khai hạ tầng AWS

Dùng Terraform và CloudFormation để quản lý và triển khai tự động hạ tầng AWS.

### 1. Các dịch vụ cần triển khai:

**1. VPC:** Tạo một VPC chứa các thành phần sau (3 điểm):
- Subnets: Bao gồm cả Public Subnet (kết nối với Internet Gateway) và Private 
Subnet (sử dụng NAT Gateway để kết nối ra ngoài).
- Internet Gateway: Kết nối với Public Subnet để cho phép các tài nguyên bên 
trong có thể truy cập Internet.
- Default Security Group: Tạo Security Group mặc định cho VPC

**2. Route Tables:** Tạo Route Tables cho Public và Private Subnet (2 điểm):
- Public Route Table: Định tuyến lưu lượng Internet thông qua Internet 
Gateway.
- Private Route Table: Định tuyến lưu lượng Internet thông qua NAT Gateway.

**3. NAT Gateway:** Cho phép các tài nguyên trong Private Subnet có thể kết nối Internet 
mà vẫn bảo đảm tính bảo mật (1 điểm).

**4. EC2:** Tạo các instance trong Public và Private Subnet, đảm bảo Public instance có thể 
truy cập từ Internet, còn Private instance chỉ có thể truy cập từ Public instance thông 
qua SSH hoặc các phương thức bảo mật khác (2 điểm).

**5. Security Groups:** Tạo các Security Groups để kiểm soát lưu lượng vào/ra của EC2 
instances (2 điểm):
- Public EC2 Security Group: Chỉ cho phép kết nối SSH (port 22) từ một IP cụ thể 
(hoặc IP của người dùng).
- Private EC2 Security Group: Cho phép kết nối từ Public EC2 instance thông qua 
port cần thiết (SSH hoặc các port khác nếu có nhu cầu).

### 2. Yêu cầu:
- Các dịch vụ phải được viết dưới dạng module.
- Phải đảm bảo an toàn bảo mật cho EC2 (thiết lập Security Groups).
- Phải có các test cases để kiểm tra từng dịch vụ được triển khai thành công