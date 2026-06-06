data "aws_ami" "operating_system" {
  most_recent = true
  owners      = var.ami_owners
  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

resource "aws_instance" "master" {
  ami                    = data.aws_ami.operating_system.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.public_sg_id]
  key_name               = var.key_name

  tags = {
    Name = "group7-master-node"
  }
}

resource "aws_instance" "worker" {
  count                  = 2
  ami                    = data.aws_ami.operating_system.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.private_sg_id]
  key_name               = var.key_name

  tags = {
    Name = "group7-worker-node-${count.index + 1}"
  }
}
