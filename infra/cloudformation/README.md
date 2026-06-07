# Lab 2 - Câu 2: Triển khai hạ tầng AWS bằng CloudFormation và CodePipeline

Thư mục này hoàn thành phần triển khai hạ tầng AWS bằng CloudFormation và tự động hóa quy trình build/deploy bằng AWS CodeCommit, CodeBuild và CodePipeline.

## Mục tiêu

- Dùng CloudFormation để triển khai lại hạ tầng đã làm ở Lab 1: VPC, public/private subnet, Internet Gateway, NAT Gateway, route table, Security Group và EC2.
- Module hóa CloudFormation bằng nested stacks.
- Dùng CodeBuild để kiểm tra template bằng `cfn-lint`, `aws cloudformation validate-template` và Taskcat.
- Dùng CodePipeline để tự động deploy stack CloudFormation từ source code trên CodeCommit.

## Cấu trúc thư mục

```text
infra/cloudformation/
|-- README.md
|-- buildspec.yml
|-- pipeline.yaml
|-- .taskcat.yml
|-- parameters/
|   `-- dev.json
`-- templates/
    |-- main.yaml
    |-- network.yaml
    |-- security-groups.yaml
    |-- compute.yaml
    `-- alb.yaml
```

## Kiến trúc hạ tầng

`templates/main.yaml` là root stack và gọi các nested stack sau:

- `network.yaml`: tạo VPC, 2 public subnet, 1 private subnet, Internet Gateway, NAT Gateway, public route table và private route table.
- `security-groups.yaml`: tạo Security Group cho ALB, public EC2 và private EC2.
- `compute.yaml`: tạo 1 EC2 public master node và 2 EC2 private worker nodes.
- `alb.yaml`: tạo Application Load Balancer, target group, listener HTTP port 80 và attach 2 worker nodes.

CloudFormation cũng tạo EC2 KeyPair tự động trong root stack. Private key được AWS lưu trong SSM Parameter Store theo đường dẫn `/ec2/keypair/<KeyPairId>`.

## Tái sử dụng hạ tầng cho Lab 2 câu 3

Hạ tầng này được thiết kế để dùng tiếp cho pipeline microservices ở câu 3:

- Public EC2 `master-node` được bootstrap thành k3s server/control-plane.
- Hai private EC2 `worker-node-1` và `worker-node-2` được bootstrap thành k3s agent/worker.
- Worker nodes kết nối tới k3s server qua private IP của master, port `6443`.
- ALB nhận HTTP port `80` từ Internet và forward vào worker nodes ở Kubernetes NodePort `30080`.
- Khi triển khai microservices ở câu 3, Kubernetes Service nên dùng `type: NodePort` và `nodePort: 30080` để app truy cập được qua `http://<AlbDnsName>`.

Tham số `K3sToken` là shared token để worker join vào k3s server. Trong môi trường lab có default token để dễ chạy, còn khi triển khai thật nên truyền token riêng và không commit token vào source.

## Bảo mật

- Public EC2 chỉ mở SSH port `22` từ tham số `AllowedSshCidr`.
- Public EC2 mở thêm k3s API port `6443` từ Security Group của private EC2 để worker nodes join cluster.
- Giá trị mặc định của `AllowedSshCidr` là `203.0.113.10/32`, đây là IP ví dụ không dùng để truy cập thật. Khi deploy cần thay bằng public IP của người dùng, ví dụ `203.0.113.10/32`.
- Private EC2 không có public IP.
- Private EC2 chỉ cho phép SSH port `22` từ Security Group của public EC2.
- Private EC2 cho phép Kubernetes NodePort `30080` từ Security Group của ALB.
- Các port nội bộ cho k3s gồm UDP `8472` cho flannel VXLAN và TCP `10250` cho kubelet.
- Security Group, ALB, Target Group và KeyPair không dùng physical name cố định để tránh lỗi trùng tên khi Taskcat hoặc pipeline chạy nhiều lần.

## Quy trình CI/CD

Pipeline được định nghĩa trong `pipeline.yaml` và gồm 3 stage:

```text
CodeCommit -> CodeBuild -> CloudFormation Deploy
```

1. `Source`: lấy source từ AWS CodeCommit.
2. `BuildAndValidate`: CodeBuild chạy `buildspec.yml`.
   - Cài `cfn-lint` và `taskcat`.
   - Chạy `cfn-lint` cho toàn bộ template.
   - Chạy `aws cloudformation validate-template` cho các nested template.
   - Chạy `aws cloudformation package` để upload nested template lên S3 artifact bucket.
   - Validate file `packaged.yaml`.
   - Chạy Taskcat nếu `TaskcatEnabled=true`.
3. `Deploy`: CodePipeline dùng CloudFormation action để deploy `packaged.yaml`.

## Triển khai pipeline

Chạy lệnh sau để tạo CodeCommit repository, CodeBuild project, CodePipeline, S3 artifact bucket và các IAM role liên quan.

Trước khi chạy, lấy public IP hiện tại và truyền vào `AllowedSshCidr` theo dạng `x.x.x.x/32`. Không copy nguyên chuỗi `<YOUR_PUBLIC_IP>/32` vì CloudFormation sẽ báo lỗi pattern.

```bash
MY_PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)
```

Với PowerShell:

```powershell
$MY_PUBLIC_IP = (Invoke-RestMethod https://checkip.amazonaws.com).Trim()
```

```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/pipeline.yaml \
  --stack-name group7-cfn-pipeline-stack \
  --region ap-southeast-1 \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    PipelineName=group7-cfn-pipeline \
    RepositoryName=group7-cfn-source \
    BranchName=main \
    InfrastructureStackName=group7-cloudformation-lab \
    ProjectName=group7-cfn \
    VpcCidr=10.0.0.0/16 \
    AllowedSshCidr=${MY_PUBLIC_IP}/32 \
    MasterInstanceType=t2.small \
    WorkerInstanceType=t2.large \
    K3sToken=group7-k3s-bootstrap-token \
    TaskcatEnabled=true
```

Với PowerShell:

```powershell
aws cloudformation deploy `
  --template-file infra/cloudformation/pipeline.yaml `
  --stack-name group7-cfn-pipeline-stack `
  --region ap-southeast-1 `
  --capabilities CAPABILITY_NAMED_IAM `
  --parameter-overrides `
    PipelineName=group7-cfn-pipeline `
    RepositoryName=group7-cfn-source `
    BranchName=main `
    InfrastructureStackName=group7-cloudformation-lab `
    ProjectName=group7-cfn `
    VpcCidr=10.0.0.0/16 `
    AllowedSshCidr=$MY_PUBLIC_IP/32 `
    MasterInstanceType=t2.small `
    WorkerInstanceType=t2.large `
    K3sToken=group7-k3s-bootstrap-token `
    TaskcatEnabled=true
```

Taskcat tạo stack test thật, NAT Gateway, EC2 và ALB nên có thể phát sinh chi phí. Nếu chỉ muốn chạy lint/package/deploy, đặt `TaskcatEnabled=false`.

## Đẩy source lên CodeCommit

Sau khi tạo pipeline, lấy URL CodeCommit từ output `CodeCommitCloneUrlHttp`, sau đó push source của repo hiện tại lên CodeCommit:

```bash
git remote add codecommit <CODECOMMIT_CLONE_URL_HTTP>
git push codecommit feat/cloudformation:main
```

Pipeline sẽ tự chạy khi branch `main` của CodeCommit có commit mới.

## Kiểm tra thủ công CloudFormation

Nếu muốn kiểm tra template trước khi dùng pipeline:

```bash
cd infra/cloudformation

cfn-lint --ignore-checks W3002 \
  templates/main.yaml \
  templates/network.yaml \
  templates/security-groups.yaml \
  templates/compute.yaml \
  templates/alb.yaml

aws cloudformation validate-template --template-body file://templates/network.yaml --region ap-southeast-1
aws cloudformation validate-template --template-body file://templates/security-groups.yaml --region ap-southeast-1
aws cloudformation validate-template --template-body file://templates/compute.yaml --region ap-southeast-1
aws cloudformation validate-template --template-body file://templates/alb.yaml --region ap-southeast-1
```

Root template `templates/main.yaml` dùng nested template local path, nên phải package trước khi validate/deploy trên AWS:

```bash
aws cloudformation package \
  --template-file templates/main.yaml \
  --s3-bucket <CFN_ARTIFACT_BUCKET> \
  --output-template-file packaged.yaml \
  --region ap-southeast-1

aws cloudformation validate-template --template-body file://packaged.yaml --region ap-southeast-1
```

## Chạy Taskcat thủ công

```bash
cd infra/cloudformation
taskcat test run -c .taskcat.yml
```

Taskcat sẽ tạo stack test theo `.taskcat.yml`, kiểm tra stack có tạo thành công hay không, sau đó xóa stack test.

## Lấy output sau deploy

```bash
aws cloudformation describe-stacks \
  --stack-name group7-cloudformation-lab \
  --region ap-southeast-1 \
  --query "Stacks[0].Outputs"
```

Các output quan trọng:

- `VpcId`: VPC đã tạo.
- `DefaultSecurityGroupId`: Default Security Group của VPC.
- `MasterPublicIp`: public IP của EC2 public.
- `WorkerPrivateIps`: private IP của 2 EC2 private.
- `MasterPrivateIp`: private IP của k3s server.
- `AlbDnsName`: DNS public của ALB.
- `KeyPairId`: ID dùng để lấy private key từ SSM Parameter Store.

## Lấy private key để SSH

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

SSH vào public EC2:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<MASTER_PUBLIC_IP>
```

Từ public EC2, SSH vào private EC2:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<WORKER_PRIVATE_IP>
```

## Kiểm tra k3s sau khi deploy

SSH vào public EC2 master node:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<MASTER_PUBLIC_IP>
```

Kiểm tra cluster:

```bash
sudo kubectl get nodes -o wide
sudo kubectl get pods -A
```

Kết quả mong đợi là có 3 nodes:

- `group7-cfn-master`
- `group7-cfn-worker-1`
- `group7-cfn-worker-2`

Ví dụ deploy nhanh một service test qua NodePort `30080`:

```bash
cat <<'EOF' > demo-nodeport.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-nginx
  template:
    metadata:
      labels:
        app: demo-nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: demo-nginx
spec:
  type: NodePort
  selector:
    app: demo-nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF

sudo kubectl apply -f demo-nodeport.yaml
sudo kubectl get pods -o wide
sudo kubectl get svc demo-nginx
```

Sau đó mở:

```text
http://<AlbDnsName>
```

Nếu service chạy đúng, ALB sẽ forward traffic vào NodePort `30080` trên worker nodes.

## Test cases

| Test case | Công cụ | Kết quả mong đợi |
| --- | --- | --- |
| Kiểm tra cú pháp template | `cfn-lint` | Không có lỗi lint nghiêm trọng |
| Kiểm tra nested template hợp lệ | `aws cloudformation validate-template` | `network`, `security-groups`, `compute`, `alb` hợp lệ |
| Kiểm tra package root stack | `aws cloudformation package` | Sinh ra `packaged.yaml` với nested template đã upload lên S3 |
| Kiểm tra deploy integration | Taskcat | Stack test tạo thành công rồi được xóa |
| Kiểm tra VPC | CloudFormation outputs/AWS Console | Có VPC và default SG |
| Kiểm tra route public | AWS Console/CLI | Public route table có route `0.0.0.0/0` qua Internet Gateway |
| Kiểm tra route private | AWS Console/CLI | Private route table có route `0.0.0.0/0` qua NAT Gateway |
| Kiểm tra EC2 public | AWS Console/CLI | Master node nằm trong public subnet và có public IP |
| Kiểm tra EC2 private | AWS Console/CLI | Worker nodes nằm trong private subnet và không có public IP |
| Kiểm tra bảo mật SSH | Security Group | Public EC2 chỉ mở SSH từ `AllowedSshCidr`, private EC2 chỉ mở SSH từ public EC2 SG |
| Kiểm tra k3s cluster | `kubectl get nodes` | Master và 2 worker nodes ở trạng thái `Ready` |
| Kiểm tra ALB cho app câu 3 | Browser/curl | `http://<AlbDnsName>` trả response từ Kubernetes Service NodePort `30080` |

## Xóa tài nguyên

Xóa hạ tầng được pipeline deploy:

```bash
aws cloudformation delete-stack \
  --stack-name group7-cloudformation-lab \
  --region ap-southeast-1
```

Xóa pipeline stack:

```bash
aws cloudformation delete-stack \
  --stack-name group7-cfn-pipeline-stack \
  --region ap-southeast-1
```

Nếu S3 artifact bucket còn object, cần empty bucket trước khi xóa pipeline stack.
