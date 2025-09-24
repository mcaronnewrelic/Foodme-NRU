terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend will be configured via -backend-config during terraform init
  # No backend block needed - prevents "empty value" error
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
    }
  }
}
