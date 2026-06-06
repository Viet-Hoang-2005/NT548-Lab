resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "group7-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "group7-nat"
  }
}
