terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Generate an SSH Key Pair
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "group7-keypair"
  public_key = tls_private_key.my_key.public_key_openssh
}

module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "nat_gateway" {
  source           = "./modules/nat_gateway"
  public_subnet_id = module.vpc.public_subnet_id
  depends_on       = [module.vpc]
}

module "route_tables" {
  source            = "./modules/route_tables"
  vpc_id            = module.vpc.vpc_id
  igw_id            = module.vpc.igw_id
  nat_gateway_id    = module.nat_gateway.nat_gateway_id
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
}

module "security_group" {
  source         = "./modules/security_group"
  vpc_id         = module.vpc.vpc_id
  allowed_ssh_ip = var.allowed_ssh_ip
}

module "ec2" {
  source            = "./modules/ec2"
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  public_sg_id      = module.security_group.public_sg_id
  private_sg_id     = module.security_group.private_sg_id
  key_name          = aws_key_pair.generated_key.key_name
  instance_type     = var.instance_type
  ami_name_filter   = var.ami_name_filter
  ami_owners        = var.ami_owners
}
