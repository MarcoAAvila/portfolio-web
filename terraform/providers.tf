# =============================================================================
# providers.tf
#
# Two AWS provider instances are required:
#   1. Primary (var.aws_region) — S3, DynamoDB, Lambda, API GW, IAM.
#   2. Aliased "us_east_1" — ACM certificate only; CloudFront exclusively
#      accepts certificates provisioned in us-east-1.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # ---------------------------------------------------------------------------
  # Remote backend (recommended for team or multi-machine workflows):
  # Stores tfstate in S3 with DynamoDB locking instead of local disk.
  # Uncomment once the state bucket exists.
  # ---------------------------------------------------------------------------
  # backend "s3" {
  #   bucket         = "marcoaavila-terraform-state"
  #   key            = "portfolio-web/terraform.tfstate"
  #   region         = "eu-west-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock-table"
  # }
}

# -----------------------------------------------------------------------------
# Primary provider — default_tags propagates common labels to every resource
# without repeating them in individual tag blocks.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "portfolio-web"
      Owner       = "marcoaavila"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Secondary provider (alias = "us_east_1"):
# Referenced explicitly with `provider = aws.us_east_1` in acm.tf.
# CloudFront requires the ACM certificate to exist in us-east-1, regardless
# of the region where the distribution is managed.
# -----------------------------------------------------------------------------
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "portfolio-web"
      Owner       = "marcoaavila"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}
