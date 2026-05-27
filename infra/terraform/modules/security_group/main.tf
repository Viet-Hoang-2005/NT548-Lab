resource "aws_security_group" "alb_sg" {
  name        = "group7-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "group7-alb-sg"
  }
}

resource "aws_security_group" "public_ec2" {
  name        = "group7-public-ec2-sg"
  description = "Security group for public EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "group7-public-ec2-sg"
  }
}

resource "aws_security_group" "private_ec2" {
  name        = "group7-private-ec2-sg"
  description = "Security group for private EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from public SG"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public_ec2.id]
  }

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "group7-private-ec2-sg"
  }
}
