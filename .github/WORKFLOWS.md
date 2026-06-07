# GitHub Actions CI/CD

Thu muc `.github/workflows` chua cac workflow tu dong kiem tra va trien khai ha tang AWS.

Tat ca workflow dang dung AWS OIDC, nen khong can luu `AWS_ACCESS_KEY_ID` va `AWS_SECRET_ACCESS_KEY` trong GitHub Secrets. Repository can cau hinh variable `IAM_ROLE_ARN` tro den IAM Role da tao trong `infra/cicd`.

## 1. Terraform Plan (`terraform-plan.yml`)

**Muc dich:** Kiem tra Terraform truoc khi merge vao `main`.

**Kich hoat khi:** Co Pull Request vao nhanh `main` va co thay doi trong `infra/terraform/**`.

**Luong hoat dong:**

1. Checkout source code.
2. Dang nhap AWS bang OIDC.
3. Cai Terraform `1.9.0`.
4. Chay `terraform init`.
5. Chay `terraform validate`.
6. Chay Checkov de scan bao mat Terraform.
7. Chay `terraform plan`.
8. Comment ket qua vao Pull Request.
9. Neu Checkov hoac Terraform Plan fail thi workflow fail.

## 2. Terraform Apply (`terraform-apply.yml`)

**Muc dich:** Tu dong deploy ha tang Terraform sau khi code duoc merge vao `main`.

**Kich hoat khi:** Co push hoac merge vao nhanh `main` va co thay doi trong `infra/terraform/**`.

**Luong hoat dong:**

1. Checkout source code.
2. Dang nhap AWS bang OIDC.
3. Cai Terraform `1.9.0`.
4. Chay `terraform init`.
5. Chay `terraform apply -auto-approve`.

## 3. CloudFormation Validate (`cloudformation-validate.yml`)

**Muc dich:** Kiem tra CloudFormation templates truoc khi merge vao `main`.

**Kich hoat khi:** Co Pull Request vao nhanh `main` va co thay doi trong `infra/cloudformation/**`.

**Luong hoat dong:**

1. Checkout source code.
2. Dang nhap AWS bang OIDC.
3. Cai `cfn-lint`.
4. Chay `cfn-lint` cho root template va cac nested stack modules.
5. Chay `aws cloudformation validate-template` cho `main.yaml` va tung module.
6. Comment ket qua validate vao Pull Request.

## 4. CloudFormation Deploy (`cloudformation-deploy.yml`)

**Muc dich:** Tu dong package va deploy CloudFormation nested stacks sau khi code duoc merge vao `main`.

**Kich hoat khi:** Co push hoac merge vao nhanh `main` va co thay doi trong `infra/cloudformation/**`.

**Bien GitHub can cau hinh:**

- `IAM_ROLE_ARN`: IAM Role ARN ma GitHub Actions se assume bang OIDC.
- `ALLOWED_SSH_CIDR`: IP/CIDR duoc phep SSH vao public EC2, nen dat dang `<YOUR_PUBLIC_IP>/32`.
- `CFN_ARTIFACT_BUCKET`: S3 bucket dung de upload nested templates khi chay `aws cloudformation package`. Nen dung output `cloudformation_artifact_bucket_name` cua `infra/cicd`. Neu khong cau hinh, workflow dung mac dinh `group7-cfn-artifacts`.

**Luong hoat dong:**

1. Checkout source code.
2. Dang nhap AWS bang OIDC.
3. Kiem tra `ALLOWED_SSH_CIDR` da duoc cau hinh.
4. Cai va chay `cfn-lint`.
5. Chay `aws cloudformation package` de upload nested templates len S3 va tao `packaged.yaml`.
6. Chay `aws cloudformation deploy` de cap nhat stack `group7-cloudformation-lab`.
