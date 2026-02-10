# mcp-infra

OpenTofu infrastructure-as-code repository targeting AWS. Houses reusable infrastructure modules designed to be versioned and consumed by other repositories.

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.11.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- AWS account with appropriate permissions

## Repository Structure

```text
.
├── CLAUDE.md                    # Project conventions and security practices
├── docs/
│   ├── prd.md                   # Product requirements document
│   ├── architecture.md          # Infrastructure diagrams (Mermaid)
│   └── infracost-setup.md       # CI cost estimation setup guide
├── infra/
│   ├── modules/
│   │   ├── vpc/                 # VPC with subnets, NAT, flow logs
│   │   └── security_groups/     # Tiered SG patterns (web/app/db/bastion)
│   ├── main.tf                  # Root config — calls modules
│   ├── variables.tf             # Root-level variables
│   ├── outputs.tf               # Root-level outputs
│   ├── providers.tf             # AWS provider config
│   ├── versions.tf              # OpenTofu and provider version constraints
│   └── terraform.tfvars.example  # Example variable values
└── .github/
    └── workflows/
        └── tofu-plan.yml        # CI: tofu plan + Infracost on PRs
```

## Quick Start

```bash
cd infra

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Initialize
tofu init

# Plan
tofu plan

# Apply
tofu apply
```

## Modules

### VPC (`infra/modules/vpc`)

Creates a VPC with public/private subnets across multiple AZs, Internet Gateway, optional NAT Gateway, VPC Flow Logs, and hardened default resources.

[View module documentation](infra/modules/vpc/README.md)

### Security Groups (`infra/modules/security_groups`)

Reusable security group patterns for web, application, database, and bastion tiers with layered access control.

[View module documentation](infra/modules/security_groups/README.md)

## Consuming Modules

Reference modules via git source URLs with version pinning:

```hcl
module "vpc" {
  source = "git::https://github.com/jsandov/mcp-infra.git//infra/modules/vpc?ref=v1.0.0"

  cidr_block         = "10.0.0.0/16"
  environment        = "prod"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

## CI/CD

Pull requests that modify `infra/` files automatically trigger:
- **OpenTofu Plan** — format check, validation, and plan output posted as PR comment
- **Infracost** — cost breakdown posted as PR comment

See [Infracost Setup Guide](docs/infracost-setup.md) for configuring the required secrets.

## Conventions

See [CLAUDE.md](CLAUDE.md) for project conventions, security practices, and module authoring guidelines.
