# Xây dựng hạ tầng AWS bằng Terraform

Thư mục này dùng Terraform để tự động hóa việc khởi tạo hạ tầng mạng và máy chủ cơ bản trên AWS theo cấu trúc module.

Hạ tầng gồm VPC, public/private subnets, Internet Gateway, NAT Gateway, route tables, Security Groups, EC2 instances và Application Load Balancer. Các EC2 instances sử dụng Ubuntu 22.04 LTS.

## Kiến trúc hạ tầng

- **VPC**: mạng riêng ảo chứa toàn bộ tài nguyên.
- **Public Subnets**: dùng cho Application Load Balancer và Master Node.
- **Private Subnet**: dùng cho Worker Nodes.
- **Internet Gateway**: cho phép tài nguyên trong Public Subnet truy cập Internet.
- **NAT Gateway**: đặt trong Public Subnet 1, cho phép tài nguyên trong Private Subnet truy cập Internet ra ngoài.
- **Application Load Balancer**: nhận HTTP traffic từ Internet tại port `80` và phân phối vào Worker Nodes.
- **Security Groups**:
  - `group7-alb-sg`: cho phép HTTP traffic từ Internet.
  - `group7-public-ec2-sg`: cho phép SSH vào Master Node.
  - `group7-private-ec2-sg`: cho phép traffic từ ALB tại port `80` và SSH từ Master Node.
- **EC2 Instances**:
  - **1 Master Node** (`t3.small`) nằm ở Public Subnet.
  - **2 Worker Nodes** (`t3.large`) nằm ở Private Subnet.
  - Tự động tạo và quản lý RSA SSH Key Pair (`group7-keypair`).
  - Hệ điều hành: Ubuntu 22.04 LTS.

## Cấu trúc module

```text
infra/terraform/
├── main.tf              # Root module, gọi các module con và tạo Key Pair
├── variables.tf         # Các biến toàn cục
├── outputs.tf           # Thông tin xuất ra sau khi chạy (IP, Key,...)
└── modules/
    ├── vpc/             # Module lõi mạng (VPC, Subnets, IGW)
    ├── nat_gateway/     # Module cấp phát IP và NAT Gateway
    ├── route_tables/    # Module định tuyến
    ├── security_group/  # Module tường lửa
    ├── ec2/             # Module máy ảo
    └── alb/             # Module Load Balancer
```

- `main.tf`: root module, gọi các module con và tạo SSH key pair.
- `variables.tf`: khai báo biến đầu vào.
- `outputs.tf`: xuất thông tin sau khi triển khai.
- `modules/vpc`: VPC, subnets, Internet Gateway, NAT Gateway và route tables.
- `modules/security_group`: Security Groups cho ALB, public EC2 và private EC2.
- `modules/ec2`: Master Node và Worker Nodes.
- `modules/alb`: Application Load Balancer, target group và listener.

## Điều kiện cần có

- Terraform.
- AWS CLI đã cấu hình credentials nếu chạy local.
- Backend S3 `group7-tfstate-artifact` và DynamoDB table `group7-tfstate-locks` đã được tạo từ `infra/cicd`.

## Triển khai

Chạy trong thư mục `infra/terraform`:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Khi chạy `terraform apply`, xác nhận `yes` nếu triển khai thủ công.

## Lấy SSH key

Sau khi apply thành công, xuất private key ra file `.pem`:

```bash
terraform output -raw private_key_pem > group7-keypair.pem
```

Phân quyền file key:

```bash
chmod 400 group7-keypair.pem
```

Trên PowerShell:

```powershell
icacls.exe group7-keypair.pem /reset
icacls.exe group7-keypair.pem /GRANT:R "$($env:USERNAME):(R)"
icacls.exe group7-keypair.pem /inheritance:r
```

## SSH vào Master Node

Lấy public IP từ Terraform outputs, sau đó SSH:

```bash
ssh -i group7-keypair.pem ubuntu@<MASTER_NODE_PUBLIC_IP>
```

## Xóa tài nguyên

```bash
terraform destroy
```

Xác nhận `yes` khi Terraform yêu cầu.
