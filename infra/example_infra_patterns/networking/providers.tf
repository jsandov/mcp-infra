provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "opentofu"
      Environment = var.environment
    }
  }
}
