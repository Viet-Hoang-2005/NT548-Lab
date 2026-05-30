# Xây dựng hạ tầng AWS bằng CloudFormation

Thư mục này triển khai lại hạ tầng AWS bằng CloudFormation theo kiểu module hóa bằng nested stacks.

## Cấu trúc thư mục

```text
infra/cloudformation/
|-- main.yaml
`-- modules/
    |-- vpc/
    |   `-- vpc.yaml
    |-- security-group/
    |   `-- security-group.yaml
    |-- ec2/
    |   `-- ec2.yaml
    `-- alb/
        `-- alb.yaml
```

- `main.yaml`: root stack, tạo EC2 key pair và gọi các nested stacks.
- `modules/vpc/vpc.yaml`: VPC, public/private subnets, Internet Gateway, NAT Gateway và route tables.
- `modules/security-group/security-group.yaml`: Security Groups cho ALB, public EC2 và private EC2.
- `modules/ec2/ec2.yaml`: 1 public master node và 2 private worker nodes.
- `modules/alb/alb.yaml`: Application Load Balancer, target group, listener và attachment vào worker nodes.

CloudFormation không deploy nested template trực tiếp từ đường dẫn local. Vì vậy cần chạy `aws cloudformation package` để upload các template con lên S3 và sinh ra file `packaged.yaml`.

## Điều kiện cần có

- AWS CLI đã cấu hình credentials.
- S3 bucket dùng để upload nested templates, ví dụ `group7-cfn-artifacts`.
- Quyền tạo VPC, subnet, route table, NAT Gateway, EIP, Security Group, EC2, EC2 Key Pair, ALB, Target Group và đọc SSM Parameter Store.

## Package template

Chạy trong thư mục `infra/cloudformation`:

```bash
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket <YOUR_CF_ARTIFACT_BUCKET> \
  --output-template-file packaged.yaml \
  --region ap-southeast-1
```

Với PowerShell:

```powershell
aws cloudformation package `
  --template-file main.yaml `
  --s3-bucket <YOUR_CF_ARTIFACT_BUCKET> `
  --output-template-file packaged.yaml `
  --region ap-southeast-1
```

## Deploy stack

Nên thay `AllowedSshCidr` bằng public IP của bạn theo dạng `/32`, ví dụ `203.0.113.10/32`.

```bash
aws cloudformation deploy \
  --template-file packaged.yaml \
  --stack-name group7-cloudformation-lab \
  --region ap-southeast-1 \
  --capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      ProjectName=group7 \
      AllowedSshCidr=<YOUR_PUBLIC_IP>/32 \
      KeyPairName=group7-cfn-keypair \
      MasterInstanceType=t2.small \
      WorkerInstanceType=t2.large
```

Với PowerShell:

```powershell
aws cloudformation deploy `
  --template-file packaged.yaml `
  --stack-name group7-cloudformation-lab `
  --region ap-southeast-1 `
  --capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM `
  --parameter-overrides `
      ProjectName=group7 `
      AllowedSshCidr=<YOUR_PUBLIC_IP>/32 `
      KeyPairName=group7-cfn-keypair `
      MasterInstanceType=t2.small `
      WorkerInstanceType=t2.large
```

## Lấy outputs

```bash
aws cloudformation describe-stacks \
  --stack-name group7-cloudformation-lab \
  --region ap-southeast-1 \
  --query "Stacks[0].Outputs"
```

Các output quan trọng:

- `MasterPublicIp`: dùng để SSH vào public EC2.
- `KeyPairId`: dùng để lấy private key từ SSM Parameter Store.
- `LoadBalancerDnsName`: DNS public của ALB.

## Lấy private key

CloudFormation tạo `AWS::EC2::KeyPair`. Private key được AWS lưu trong SSM Parameter Store theo tên `/ec2/keypair/<KeyPairId>`.

```bash
aws ssm get-parameter \
  --name /ec2/keypair/<KEY_PAIR_ID> \
  --with-decryption \
  --region ap-southeast-1 \
  --query Parameter.Value \
  --output text > group7-cfn-keypair.pem

chmod 400 group7-cfn-keypair.pem
```

Với PowerShell:

```powershell
aws ssm get-parameter `
  --name /ec2/keypair/<KEY_PAIR_ID> `
  --with-decryption `
  --region ap-southeast-1 `
  --query Parameter.Value `
  --output text | Out-File -Encoding ascii group7-cfn-keypair.pem

icacls.exe group7-cfn-keypair.pem /reset
icacls.exe group7-cfn-keypair.pem /GRANT:R "$($env:USERNAME):(R)"
icacls.exe group7-cfn-keypair.pem /inheritance:r
```

## SSH

SSH vào public EC2:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<MASTER_PUBLIC_IP>
```

Từ public EC2, SSH vào private EC2 bằng private IP của worker:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<WORKER_PRIVATE_IP>
```

Security Group của private EC2 chỉ mở SSH port `22` từ Security Group của public EC2, nên private EC2 không bị truy cập trực tiếp từ Internet.

## Kiểm tra template

Nếu đã cài `cfn-lint`:

```bash
cfn-lint main.yaml modules/vpc/vpc.yaml modules/security-group/security-group.yaml modules/ec2/ec2.yaml modules/alb/alb.yaml
```

Kiểm tra bằng AWS CLI:

```bash
aws cloudformation validate-template --template-body file://main.yaml
```

Lưu ý: `validate-template` chỉ validate root template local. Khi deploy nested stacks, cần chạy `package` trước.

## GitHub Actions

Thư mục `.github/workflows` có 2 workflow riêng cho CloudFormation:

- `cloudformation-validate.yml`: chạy khi Pull Request thay đổi `infra/cloudformation/**`, dùng `cfn-lint` và `aws cloudformation validate-template`.
- `cloudformation-deploy.yml`: chạy khi merge hoặc push vào `main` có thay đổi `infra/cloudformation/**`, dùng `aws cloudformation package` và `aws cloudformation deploy`.

Cần cấu hình GitHub repository variables:

- `IAM_ROLE_ARN`: IAM Role ARN cho GitHub Actions OIDC.
- `ALLOWED_SSH_CIDR`: IP/CIDR được phép SSH vào public EC2, ví dụ `203.0.113.10/32`.
- `CFN_ARTIFACT_BUCKET`: S3 bucket upload nested templates. Nên dùng output `cloudformation_artifact_bucket_name` của `infra/cicd`. Nếu bỏ trống, workflow dùng `group7-cfn-artifacts`.

## Xóa tài nguyên

```bash
aws cloudformation delete-stack \
  --stack-name group7-cloudformation-lab \
  --region ap-southeast-1
```
