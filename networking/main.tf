variable "vpc_cidr" {}
variable "vpc_name" {}
variable "ap_availability_zone" {}
variable "cidr_public_subnet" {}
variable "cidr_private_subnet" {}


output "aws_infra_vpc_id" {
  value = aws_vpc.aws_infra_vpc_ap_south-1.id
}

output "aws_infra_public_subnets" {
  value = aws_subnet.aws_infra_public_subnets.*.id
}

output "public_subnet_cidr_block" {
  value = aws_subnet.aws_infra_public_subnets.*.cidr_block
}

# Setup VPC
resource "aws_vpc" "aws_infra_vpc_ap_south-1" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

# Setup public subnet
resource "aws_subnet" "aws_infra_public_subnets" {

  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.aws_infra_vpc_ap_south-1.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.ap_availability_zone, count.index)

  tags = {
    Name = "aws-infra-public-subnet-${count.index + 1}"
  }
}

# Setup private subnet
resource "aws_subnet" "aws_infra_private_subnets" {

  count             = length(var.cidr_private_subnet)
  vpc_id            = aws_vpc.aws_infra_vpc_ap_south-1.id
  cidr_block        = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.ap_availability_zone, count.index)

  tags = {
    Name = "aws-infra-private-subnet-${count.index + 1}"
  }
}

# Setup Internet Gateway
resource "aws_internet_gateway" "aws_infra_public_internet_gateway" {
  vpc_id = aws_vpc.aws_infra_vpc_ap_south-1.id

  tags = {
    Name = "aws-infra-igw"
  }
}

# public Route Table
resource "aws_route_table" "aws_infra_public_subnet_route_table" {
  vpc_id       = aws_vpc.aws_infra_vpc_ap_south-1.id
  route {
    cidr_block = "0.0.0.0/0"                  #--------> internet request
    gateway_id = aws_internet_gateway.aws_infra_public_internet_gateway.id
  }
  tags = {
    Name       = "aws-infra-public-rt"
  }
}

# Public Route Table and Public Subnet Association
resource "aws_route_table_association" "aws_infra_public_subnet_route_table_association" {

  count          = length(aws_subnet.aws_infra_public_subnets)
  subnet_id      = aws_subnet.aws_infra_public_subnets[count.index].id
  route_table_id = aws_route_table.aws_infra_public_subnet_route_table.id

}

# Private Route Table
resource "aws_route_table" "aws_infra_private_subnet_route_table" {
  vpc_id = aws_vpc.aws_infra_vpc_ap_south-1.id
  #depends_on = [aws_nat_gateway.nat_gateway]
  tags = {
    Name = "aws-infra-private-rt"
  }
}

# private Route Table and private Subnet Association
resource "aws_route_table_association" "aws_infra_private_subnet_route_table_association" {

  count          = length(aws_subnet.aws_infra_private_subnets)
  subnet_id      = aws_subnet.aws_infra_private_subnets[count.index].id
  route_table_id = aws_route_table.aws_infra_private_subnet_route_table.id

}