# Infrastructure Root

This directory contains the root OpenTofu configuration that composes the infrastructure modules.

## Prerequisites

- OpenTofu >= 1.11.0
- AWS credentials configured (`aws configure` or environment variables)

## Usage

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize providers and modules
tofu init

# Check formatting
tofu fmt -check -recursive

# Validate configuration
tofu validate

# Preview changes
tofu plan

# Apply changes
tofu apply
```

## Variables

| Name               | Type     | Default        | Description                              |
| ------------------ | -------- | -------------- | ---------------------------------------- |
| `aws_region`       | `string` | `us-east-1`    | AWS region to deploy resources in        |
| `environment`      | `string` | `dev`          | Environment name (dev, staging, prod)    |
| `vpc_cidr`         | `string` | `10.0.0.0/16`  | CIDR block for the VPC                   |
| `enable_nat_gateway` | `bool` | `false`        | Create a NAT Gateway for private subnets |

## Backend Configuration

The default configuration uses local state. To migrate to S3 remote state:

1. Uncomment the backend block in `versions.tf`
2. Update the bucket name and region
3. Run `tofu init -migrate-state`
4. Confirm the migration when prompted

See the commented backend block in [versions.tf](versions.tf) for details.

## Modules Used

- **[vpc](modules/vpc/)** — VPC, subnets, IGW, NAT, flow logs, default resource hardening
- **[security_groups](modules/security_groups/)** — Tiered security group patterns
