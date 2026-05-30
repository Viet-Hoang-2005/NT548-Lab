# Bootstrap infrastructure for CI/CD

Thu muc `infra/cicd` dung Terraform de tao cac tai nguyen nen tang cho GitHub Actions CI/CD.

Stack nay khong tao ha tang ung dung chinh nhu VPC, EC2 hay ALB. No tao cac thanh phan dung chung de pipeline Terraform va CloudFormation co the chay an toan.

## Tai nguyen duoc tao

1. `group7-tfstate-artifact`
   S3 bucket luu remote state cua Terraform. Bucket bat versioning, server-side encryption va chan public access.

2. `group7-tfstate-locks`
   DynamoDB table dung cho Terraform state locking, tranh nhieu pipeline ghi state cung luc.

3. `group7-cfn-artifacts`
   S3 bucket luu packaged CloudFormation nested templates khi workflow chay `aws cloudformation package`. Bucket bat versioning, server-side encryption va chan public access.

4. GitHub OIDC Provider
   Thiet lap trust relationship giua AWS va GitHub Actions.

5. `github-actions-tf-role`
   IAM Role cho GitHub Actions assume bang OIDC. Role dang gan `AdministratorAccess` de phuc vu bai lab.

## Cach chay

```bash
cd infra/cicd
terraform init
terraform plan
terraform apply
```

## Outputs can dung

Sau khi apply, lay outputs:

```bash
terraform output
```

Gan cac gia tri vao GitHub repository variables:

- `github_actions_role_arn` -> `IAM_ROLE_ARN`
- `cloudformation_artifact_bucket_name` -> `CFN_ARTIFACT_BUCKET`

Ngoai ra can tu cau hinh:

- `ALLOWED_SSH_CIDR`: IP/CIDR duoc phep SSH vao public EC2, vi du `203.0.113.10/32`.

## Luu y

S3 bucket name la global unique tren AWS. Neu ten mac dinh da bi trung, doi gia tri trong `variables.tf` hoac truyen bang `terraform.tfvars`.
