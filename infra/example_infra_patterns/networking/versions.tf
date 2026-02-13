terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend (uncomment when ready to migrate from local state):
  #
  # To migrate:
  #   1. Uncomment the backend block below
  #   2. Run: tofu init -migrate-state
  #   3. Confirm the migration when prompted
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "cloud-voyager-infra/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
