terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration will be provided via -backend-config flags during init
  # This prevents the "empty value" error while allowing dynamic configuration
  backend "s3" {
    # Configuration provided via CLI flags in workflow
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
