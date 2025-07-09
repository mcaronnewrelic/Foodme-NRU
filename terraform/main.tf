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
    bucket = "foodme-terraform-state-bucket"
    key    = "foodme/terraform.tfstate"
    region = "us-west-2"

    # Enable state locking with DynamoDB
    dynamodb_table = "foodme-terraform-locks"
    encrypt        = true
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
