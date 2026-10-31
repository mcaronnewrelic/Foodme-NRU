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
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
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
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Database password must be at least 12 characters long."
  }
}

variable "db_port" {
  description = "PostgreSQL database port"
  type        = number
  default     = 5432
}

variable "pgdata_path" {
  description = "PostgreSQL data directory path"
  type        = string
  default     = "/var/lib/pgsql/data"
}

variable "use_existing_vpc" {
  description = "Whether to use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "create_alb" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "ID of existing VPC to use when use_existing_vpc is true"
  type        = string
  default     = ""

  validation {
    condition     = length(var.existing_vpc_id) > 0 || length(var.existing_vpc_id) == 0
    error_message = "existing_vpc_id must be a valid VPC ID when provided."
  }
}

variable "existing_public_subnet_id" {
  description = "ID of existing public subnet to use when use_existing_vpc is true"
  type        = string
  default     = ""

  validation {
    condition     = length(var.existing_public_subnet_id) > 0 || length(var.existing_public_subnet_id) == 0
    error_message = "existing_public_subnet_id must be a valid subnet ID when provided."
  }
}
