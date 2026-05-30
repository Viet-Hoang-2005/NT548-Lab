# AWS infrastructure with CloudFormation

Thu muc nay trien khai lai bai Lab 1 bang CloudFormation theo kieu module hoa bang nested stacks.

## Cau truc

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

- `main.yaml`: root stack, tao EC2 key pair va goi cac nested stacks.
- `modules/vpc/vpc.yaml`: VPC, public/private subnets, Internet Gateway, NAT Gateway, route tables.
- `modules/security-group/security-group.yaml`: Security Group cho ALB, public EC2 va private EC2.
- `modules/ec2/ec2.yaml`: 1 public master node va 2 private worker nodes.
- `modules/alb/alb.yaml`: Application Load Balancer, target group, listener va attachment vao worker nodes.

CloudFormation khong doc duoc nested template truc tiep tu file local khi deploy len AWS. Vi vay can chay `aws cloudformation package` de upload cac file trong `modules/` len S3 va sinh ra file template da dong goi.

## Dieu kien can co

- AWS CLI da cau hinh credentials.
- Mot S3 bucket de upload nested templates.
- Quyen tao VPC, subnet, route table, NAT Gateway, EIP, Security Group, EC2, EC2 Key Pair, ALB, Target Group va doc SSM Parameter Store.

## Package template

Chay trong thu muc `infra/cloudformation`:

```bash
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket <YOUR_CF_ARTIFACT_BUCKET> \
  --output-template-file packaged.yaml \
  --region ap-southeast-1
```

Voi PowerShell:

```powershell
aws cloudformation package `
  --template-file main.yaml `
  --s3-bucket <YOUR_CF_ARTIFACT_BUCKET> `
  --output-template-file packaged.yaml `
  --region ap-southeast-1
```

## Deploy stack

Nen thay `AllowedSshCidr` bang public IP cua may ban theo dang `/32`, vi du `203.0.113.10/32`.

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

Voi PowerShell:

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

## Lay output

```bash
aws cloudformation describe-stacks \
  --stack-name group7-cloudformation-lab \
  --region ap-southeast-1 \
  --query "Stacks[0].Outputs"
```

Can luu lai hai gia tri:

- `MasterPublicIp`: dung de SSH vao public EC2.
- `KeyPairId`: dung de lay private key tu SSM Parameter Store.
- `LoadBalancerDnsName`: DNS public cua ALB.

## Lay private key

CloudFormation tao `AWS::EC2::KeyPair`. Private key duoc AWS luu trong SSM Parameter Store theo ten `/ec2/keypair/<KeyPairId>`.

```bash
aws ssm get-parameter \
  --name /ec2/keypair/<KEY_PAIR_ID> \
  --with-decryption \
  --region ap-southeast-1 \
  --query Parameter.Value \
  --output text > group7-cfn-keypair.pem

chmod 400 group7-cfn-keypair.pem
```

Voi PowerShell:

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

SSH vao public EC2:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<MASTER_PUBLIC_IP>
```

Tu public EC2, SSH vao private EC2 bang private IP cua worker:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<WORKER_PRIVATE_IP>
```

Security Group cua private EC2 chi mo SSH port 22 tu Security Group cua public EC2, nen private EC2 khong bi truy cap truc tiep tu Internet.

## Kiem tra template

Neu da cai `cfn-lint`:

```bash
cfn-lint main.yaml modules/vpc/vpc.yaml modules/security-group/security-group.yaml modules/ec2/ec2.yaml modules/alb/alb.yaml
```

Kiem tra voi CloudFormation:

```bash
aws cloudformation validate-template --template-body file://main.yaml
```

Luu y: `validate-template` chi validate root template local. Khi deploy nested stacks, hay dung `package` truoc.

## GitHub Actions

Thu muc `.github/workflows` co 2 workflow rieng cho CloudFormation:

- `cloudformation-validate.yml`: chay khi Pull Request thay doi `infra/cloudformation/**`, dung `cfn-lint` va `aws cloudformation validate-template`.
- `cloudformation-deploy.yml`: chay khi merge/push vao `main` co thay doi `infra/cloudformation/**`, dung `aws cloudformation package` va `aws cloudformation deploy`.

Can cau hinh GitHub repository variables:

- `IAM_ROLE_ARN`: IAM Role ARN cho GitHub Actions OIDC.
- `ALLOWED_SSH_CIDR`: IP/CIDR duoc phep SSH vao public EC2, vi du `203.0.113.10/32`.
- `CFN_ARTIFACT_BUCKET`: S3 bucket upload nested templates. Nen dung output `cloudformation_artifact_bucket_name` cua `infra/cicd`. Neu bo trong, workflow dung `group7-cfn-artifacts`.

## Xoa tai nguyen

```bash
aws cloudformation delete-stack \
  --stack-name group7-cloudformation-lab \
  --region ap-southeast-1
```
