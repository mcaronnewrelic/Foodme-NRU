variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "app_version" {
  description = "Application version/commit hash"
  type        = string
  default     = "latest"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "AWS key pair name for EC2 access"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation (e.g., '192.168.1.1/32' for single IP, '192.168.1.0/24' for subnet)."
  }
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "create_alb" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = false
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "use_existing_vpc" {
  description = "Whether to use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "ID of existing VPC to use (required if use_existing_vpc is true)"
  type        = string
  default     = ""
}

variable "existing_public_subnet_id" {
  description = "ID of existing public subnet to use (required if use_existing_vpc is true)"
  type        = string
  default     = ""
}

variable "existing_private_subnet_id" {
  description = "ID of existing private subnet to use (optional if use_existing_vpc is true)"
  type        = string
  default     = ""
}

variable "new_relic_license_key" {
  description = "New Relic license key for infrastructure monitoring"
  type        = string
  default     = "none"
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "foodme"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "foodme_user"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  default     = "foodme_secure_password_2025!"
  sensitive   = true
}

variable "db_port" {
  description = "PostgreSQL database port"
  type        = number
  default     = 5432
}

variable "PGDATA_PATH" {
  description = "PostgreSQL data dir"
  type        = string
  default     = "/var/lib/pgsql/data"
}
