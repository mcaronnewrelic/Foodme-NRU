terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configure this backend for remote state storage
  # Uncomment and configure when ready for production
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "foodme/terraform.tfstate"
  #   region = "us-east-1"
  # }
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
