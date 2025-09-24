# VPC and Networking Resources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC - Create new or use existing
resource "aws_vpc" "foodme" {
  count                = var.use_existing_vpc ? 0 : 1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "foodme-${var.environment}-vpc"
  }
}

# Local values for VPC reference
locals {
  vpc_id           = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.foodme[0].id
  public_subnet_id = var.use_existing_vpc ? var.existing_public_subnet_id : aws_subnet.foodme_public[0].id
}

resource "aws_internet_gateway" "foodme" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id

  tags = {
    Name = "foodme-${var.environment}-igw"
  }
}

resource "aws_subnet" "foodme_public" {
  count                   = var.use_existing_vpc ? 0 : 1
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "foodme-${var.environment}-public-subnet"
  }
}

resource "aws_route_table" "foodme_public" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foodme[0].id
  }

  tags = {
    Name = "foodme-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "foodme_public" {
  count          = var.use_existing_vpc ? 0 : 1
  subnet_id      = local.public_subnet_id
  route_table_id = aws_route_table.foodme_public[0].id
}
