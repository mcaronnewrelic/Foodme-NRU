# EC2 Instance and Related Resources
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

resource "aws_instance" "foodme" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = local.public_subnet_id
  vpc_security_group_ids = [aws_security_group.foodme.id]
  iam_instance_profile   = aws_iam_instance_profile.foodme_ec2.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port              = var.app_port
    environment           = var.environment
    app_version           = var.app_version
    new_relic_license_key = var.new_relic_license_key
    db_name               = var.db_name
    db_user               = var.db_user
    db_password           = var.db_password
    db_port               = var.db_port
    pgdata_path           = var.pgdata_path
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name        = "foodme-${var.environment}"
    Environment = var.environment
    Application = "foodme"
    Version     = var.app_version
  }
}
