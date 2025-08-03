# create vpc
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "my-vpc"
    }
  )
}

# IGW
resource "aws_internet_gateway" "main_vpc_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(
    var.tags,
    {
      Name = "my-vpc-igw"
    }
  )
}

# public subnets
resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(
    var.tags,
    {
      Name = "public-subnet-${each.key}"
    }
  )
}
# private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags = merge(
    var.tags,
    {
      Name = "private-subnet-${each.key}"
    }
  )

}

# Create an EIP in each public subnet for the NAT Gateway
resource "aws_eip" "nat_eip" {
  # Use for_each directly on the public_subnets map
  for_each = var.public_subnets

  domain = "vpc" # Ensure the EIP is for VPC

  tags = merge(
    var.tags,
    {
      Name = "nat-eip-${each.key}" # "nat-eip-subnet-1a"
      CIDR = each.value.cidr_block
      AZ   = each.value.az # "us-east-1a"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  for_each      = var.public_subnets
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = aws_subnet.public_subnets[each.key].id
  tags = merge(
    var.tags,
    {
      Name = "nat-gateway-${each.key}" # "nat-gateway-subnet-1a"
    }
  )
}

# Route tables for public subnets
resource "aws_route_table" "public_routes" {
  for_each = var.public_subnets
  vpc_id   = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_vpc_igw.id
  }
  tags = merge(
    var.tags,
    {
      Name = "public-route-table-${each.key}"
    }
  )
}

# Route tables for private subnets
resource "aws_route_table" "private_routes" {
  for_each = var.public_subnets # Changed from var.private_subnets
  vpc_id   = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    # Now keys match perfectly!
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = merge(
    var.tags,
    {
      Name = "private-route-table-${each.key}"
    }
  )
  # enforce nat gateway creation
  depends_on = [aws_nat_gateway.nat]
}

# Route table associations for public subnets
resource "aws_route_table_association" "public_association" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_routes[each.key].id
}
# Route table associations for private subnets
resource "aws_route_table_association" "private_association" {
  for_each  = var.private_subnets
  subnet_id = aws_subnet.private_subnets[each.key].id
  # Map to route table by matching AZ
  route_table_id = [
    for pub_key, pub_value in var.public_subnets :
    aws_route_table.private_routes[pub_key].id
    if pub_value.az == each.value.az
  ][0]
}
