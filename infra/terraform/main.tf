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

  backend "s3" {
    bucket         = "group7-tfstate-artifact"
    key            = "terraform/state/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "group7-tfstate-locks"
    encrypt        = true
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

module "security_group" {
  source         = "./modules/security_group"
  vpc_id         = module.vpc.vpc_id
  allowed_ssh_ip = var.allowed_ssh_ip
}

module "ec2" {
  source               = "./modules/ec2"
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_id    = module.vpc.private_subnet_id
  public_sg_id         = module.security_group.public_sg_id
  private_sg_id        = module.security_group.private_sg_id
  key_name             = aws_key_pair.generated_key.key_name
  master_instance_type = var.master_instance_type
  worker_instance_type = var.worker_instance_type
}

module "alb" {
  source              = "./modules/alb"
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  alb_sg_id           = module.security_group.alb_sg_id
  worker_instance_ids = module.ec2.worker_instance_ids
}
