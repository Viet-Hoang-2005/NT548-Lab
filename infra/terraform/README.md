# Xây dựng hạ tầng AWS cơ bản bằng Terraform

Thư mục này sử dụng Terraform để tự động hóa việc khởi tạo một hạ tầng mạng và máy chủ cơ bản trên AWS theo chuẩn Module hóa.

Môi trường bao gồm một mạng riêng ảo (VPC) bảo mật, các tường lửa (Security Group) và hệ thống máy chủ (EC2) sử dụng hệ điều hành Ubuntu 22.04 LTS.

## Kiến trúc Hạ tầng

Hạ tầng được triển khai bao gồm các thành phần sau:

- **VPC (Virtual Private Cloud)**: Mạng riêng ảo cô lập hoàn toàn tài nguyên.

- **Public Subnets**: Dành cho các tài nguyên công khai (ALB, Master Node).

- **Private Subnet**: Dành cho các tài nguyên nội bộ (Worker Nodes).

- **Internet Gateway (IGW)**: Cho phép tài nguyên trong Public Subnet giao tiếp với Internet.

- **NAT Gateway**: Đặt ở Public Subnet 1, cho phép tài nguyên trong Private Subnet truy cập ra ngoài Internet để tải các bản cập nhật.

- **Application Load Balancer (ALB)**: Đặt ở 2 Public Subnets, đóng vai trò nhận traffic từ Internet (cổng 80) và phân phối tải vào các Worker Nodes.

- **Security Groups**:
  - `group7-alb-sg`: Cho phép nhận HTTP traffic từ Internet (0.0.0.0/0).
  - `group7-public-ec2-sg`: Cho phép SSH (Port 22) vào Master Node.
  - `group7-private-ec2-sg`: Cho phép nhận luồng từ `alb-sg` (Port 80) và giao tiếp nội bộ với Master Node.

- **EC2 Instances**:
  - **1 Master Node** (`t2.small`) nằm ở Public Subnet.
  - **2 Worker Nodes** (`t2.large`) nằm ở Private Subnet.
  - Tự động tạo và quản lý RSA SSH Key Pair (`group7-keypair`).
  - Hệ điều hành: Ubuntu 22.04 LTS.

## Cấu trúc Module

Mã nguồn được thiết kế theo cấu trúc module để dễ dàng tái sử dụng và quản lý:

```text
infra/terraform/
├── main.tf              # Root module, gọi các module con và tạo Key Pair
├── variables.tf         # Các biến toàn cục
├── outputs.tf           # Thông tin xuất ra sau khi chạy (IP, Key,...)
└── modules/
    ├── vpc/             # Module cấu hình mạng
    ├── security_group/  # Module tường lửa
    ├── ec2/             # Module máy ảo
    └── alb/             # Module Load Balancer
```

## Yêu cầu cài đặt (Prerequisites)

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (phiên bản ~> 1.0)

- AWS CLI đã được cấu hình credentials (`aws configure`) nếu bạn muốn chạy trực tiếp ở máy cá nhân.

- **Lưu ý:** Mã nguồn này đã được cấu hình để quản lý file State bằng **S3 Bucket** và khóa bằng **DynamoDB**. Mọi thao tác apply chính thức khuyến nghị nên thực hiện thông qua luồng CI/CD của GitHub Actions.

## Hướng dẫn triển khai

**Bước 1: Khởi tạo Terraform**
Tải các thư viện (providers) cần thiết về môi trường local.
```bash
terraform init
```

**Bước 2: Xem trước kế hoạch triển khai**
Kiểm tra xem Terraform sẽ tạo ra những tài nguyên nào.
```bash
terraform plan
```

**Bước 3: Thực thi tạo tài nguyên**
Triển khai hạ tầng lên AWS. Xác nhận `yes` khi được yêu cầu.
```bash
terraform apply
```

**Bước 4: Cấu hình SSH Key**
Sau khi lệnh `apply` chạy xong, hệ thống sẽ tự động tạo một cặp khóa. Bạn cần xuất khóa Private (do Terraform đánh dấu là sensitive) ra thành một file `.pem` và cấp quyền read-only:

```bash
# Lấy nội dung file pem
terraform output -raw private_key_pem > group7-keypair.pem

# Cấp quyền cho file pem
# Linux / MacOS:
chmod 400 group7-keypair.pem

# Windows (Powershell):
icacls.exe group7-keypair.pem /reset
icacls.exe group7-keypair.pem /GRANT:R "$($env:USERNAME):(R)"
icacls.exe group7-keypair.pem /inheritance:r
```

**Bước 5: Kết nối vào máy chủ**
Lấy Public IP của Master Node ở phần `Outputs` của Terraform và tiến hành SSH:
```bash
ssh -i group7-keypair.pem ubuntu@<MASTER_NODE_PUBLIC_IP>
```

## Hủy tài nguyên (Clean up)

Để xóa toàn bộ hạ tầng đã tạo và tránh phát sinh chi phí trên AWS:
```bash
terraform destroy
```
Xác nhận `yes` khi được yêu cầu.
