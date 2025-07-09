# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data sources for existing VPC (if using existing)
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.existing_vpc_id
}

data "aws_subnet" "existing_public" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.existing_public_subnet_id
}

data "aws_subnet" "existing_private" {
  count = var.use_existing_vpc && var.existing_private_subnet_id != "" ? 1 : 0
  id    = var.existing_private_subnet_id
}

# VPC - Create new or use existing
resource "aws_vpc" "foodme" {
  count                = var.use_existing_vpc ? 0 : 1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "foodme-${var.environment}-vpc-${random_id.suffix.hex}"
  }
}

# Local values to reference the correct VPC and subnets
locals {
  vpc_id             = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.foodme[0].id
  public_subnet_id   = var.use_existing_vpc ? data.aws_subnet.existing_public[0].id : aws_subnet.foodme_public[0].id
  private_subnet_id  = var.use_existing_vpc && var.existing_private_subnet_id != "" ? data.aws_subnet.existing_private[0].id : (var.use_existing_vpc ? "" : aws_subnet.foodme_private[0].id)
}

# Internet Gateway
resource "aws_internet_gateway" "foodme" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id

  tags = {
    Name = "foodme-${var.environment}-igw-${random_id.suffix.hex}"
  }
}

# Public Subnet
resource "aws_subnet" "foodme_public" {
  count                   = var.use_existing_vpc ? 0 : 1
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "foodme-${var.environment}-public-subnet-${random_id.suffix.hex}"
  }
}

# Private Subnet (for future use)
resource "aws_subnet" "foodme_private" {
  count             = var.use_existing_vpc ? 0 : 1
  vpc_id            = local.vpc_id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "foodme-${var.environment}-private-subnet-${random_id.suffix.hex}"
  }
}

# Route Table
resource "aws_route_table" "foodme_public" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foodme[0].id
  }

  tags = {
    Name = "foodme-${var.environment}-public-rt-${random_id.suffix.hex}"
  }
}

# Route Table Association
resource "aws_route_table_association" "foodme_public" {
  count          = var.use_existing_vpc ? 0 : 1
  subnet_id      = local.public_subnet_id
  route_table_id = aws_route_table.foodme_public[0].id
}

# Security Group
resource "aws_security_group" "foodme" {
  name        = "foodme-${var.environment}-sg-${random_id.suffix.hex}"
  description = "Security group for FoodMe application"
  vpc_id      = local.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Health check port
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "foodme-${var.environment}-sg"
  }
}

# Random suffix for resource names to avoid conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "foodme_ec2" {
  name = "foodme-${var.environment}-ec2-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for EC2 Instance
resource "aws_iam_role_policy" "foodme_ec2" {
  name = "foodme-${var.environment}-ec2-policy-${random_id.suffix.hex}"
  role = aws_iam_role.foodme_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "foodme_ec2" {
  name = "foodme-${var.environment}-ec2-profile-${random_id.suffix.hex}"
  role = aws_iam_role.foodme_ec2.name
}

# EC2 Instance
resource "aws_instance" "foodme" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = local.public_subnet_id
  vpc_security_group_ids = [aws_security_group.foodme.id]
  iam_instance_profile   = aws_iam_instance_profile.foodme_ec2.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port    = var.app_port
    environment = var.environment
    app_version = var.app_version
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name        = "foodme-${var.environment}"
    Environment = var.environment
    Application = "FoodMe"
    Version     = var.app_version
  }
}

# Application Load Balancer (optional)
resource "aws_lb" "foodme" {
  count              = var.create_alb ? 1 : 0
  name               = "foodme-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.foodme.id]
  subnets            = local.private_subnet_id != "" ? [local.public_subnet_id, local.private_subnet_id] : [local.public_subnet_id]

  enable_deletion_protection = false

  tags = {
    Name = "foodme-${var.environment}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "foodme" {
  count    = var.create_alb ? 1 : 0
  name     = "foodme-${var.environment}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "foodme" {
  count            = var.create_alb ? 1 : 0
  target_group_arn = aws_lb_target_group.foodme[0].arn
  target_id        = aws_instance.foodme.id
  port             = var.app_port
}

# Load Balancer Listener
resource "aws_lb_listener" "foodme" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.foodme[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.foodme[0].arn
  }
}

# HTTPS Listener (if SSL certificate is provided)
resource "aws_lb_listener" "foodme_https" {
  count             = var.create_alb && var.ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.foodme[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.foodme[0].arn
  }
}
