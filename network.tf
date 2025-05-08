


# Get existing IGW for default VPC
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block = "172.31.100.0/24"  # for private_1
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block = "172.31.101.0/24"  # for private_2
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = false
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
}

# Route Table Associations
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# NAT Gateway Setup
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnets.default.ids[0]
  depends_on    = [data.aws_internet_gateway.default]
}
