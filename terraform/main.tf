terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Using S3 backend for remote state storage
  # This ensures state consistency across GitHub Actions runs
  backend "s3" {
    bucket         = var.terraform_state_bucket
    key            = "${var.environment}/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = var.terraform_lock_table
    encrypt        = true
    
    # Enhanced lock configuration
    skip_region_validation      = false
    skip_credentials_validation = false
    skip_metadata_api_check    = false
    force_path_style           = false
  }
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state storage"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.terraform_state_bucket))
    error_message = "Bucket name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "terraform_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-locks"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "FoodMe"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "foodme"
    }
  }
}
