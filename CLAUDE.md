# CLAUDE.md — cloud-voyager-infra Project Conventions

This file defines coding standards, security practices, and module authoring guidelines for the `cloud-voyager-infra` OpenTofu infrastructure-as-code repository.

---

## OpenTofu / HCL Conventions

### File Naming

Every OpenTofu configuration directory must follow this file structure:

| File              | Purpose                                      |
| ----------------- | -------------------------------------------- |
| `main.tf`         | Primary resource definitions                 |
| `variables.tf`    | Input variable declarations                  |
| `outputs.tf`      | Output value declarations                    |
| `providers.tf`    | Provider configuration (root modules only)   |
| `versions.tf`     | OpenTofu and provider version constraints    |

### Naming Conventions

- Use `snake_case` for all variable names, output names, resource names, and local values
- Names must be descriptive and self-documenting (e.g., `public_subnet_ids` not `pub_sn`)
- Boolean variables should use `enable_` or `is_` prefixes (e.g., `enable_nat_gateway`)
- List/map variables should use plural names (e.g., `availability_zones`, `tags`)

### Formatting and Validation

- **`tofu fmt`** must pass before every commit — no exceptions
- **`tofu validate`** must pass before every commit
- Use 2-space indentation (OpenTofu default)
- One blank line between resource blocks
- Group related resources together with a comment header

---

## Security Practices

### Secret Management

- **NEVER** hardcode secrets, passwords, API keys, or tokens in `.tf` files
- **NEVER** commit `.tfvars` files containing sensitive values — these are gitignored
- Use `*.tfvars.example` files as templates showing required variables without real values
- Store secrets in **AWS Secrets Manager** or **SSM Parameter Store**
- Reference secrets using `data` sources at runtime, not as plain-text variables:
  ```hcl
  data "aws_ssm_parameter" "db_password" {
    name = "/myapp/db/password"
  }
  ```
- Mark sensitive variables and outputs with `sensitive = true`

### IAM Least Privilege

- **NEVER** use wildcard `*` for IAM actions (e.g., `"s3:*"` is prohibited)
- **NEVER** use wildcard `*` for IAM resources unless absolutely necessary and documented
- All IAM roles and policies must follow the principle of least privilege
- Prefer AWS managed policies where they match the exact required permissions
- When custom policies are needed, scope actions and resources as narrowly as possible
- Include `condition` blocks to further restrict access where applicable
- Document the rationale for any IAM policy in a comment above the resource

### State File Security

- State files (`*.tfstate`, `*.tfstate.*`) must **NEVER** be committed to git
- When remote state is configured:
  - S3 bucket must have **server-side encryption** enabled (AES-256 or KMS)
  - **DynamoDB table** must be used for state locking to prevent concurrent modifications
  - S3 bucket access must be restricted via IAM policies to authorized roles only
  - Enable **versioning** on the S3 bucket for state recovery
  - Block public access on the state bucket

### Provider Constraints

- **Always** pin provider versions with both lower and upper bounds
- **NEVER** use `>=` without an upper bound — this risks breaking changes
- Use the pessimistic constraint operator `~>` for minor version flexibility:
  ```hcl
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  ```
- Pin the OpenTofu version itself in `versions.tf`

---

## Module Authoring Guidelines

### Required Files

Every module must contain:

| File             | Purpose                                          |
| ---------------- | ------------------------------------------------ |
| `main.tf`        | Resource definitions                             |
| `variables.tf`   | All input variables with `description` and `type`|
| `outputs.tf`     | All outputs with `description`                   |
| `README.md`      | Usage docs, inputs/outputs tables, examples      |

### Variable Requirements

- Every variable **must** have a `description` field
- Every variable **must** have a `type` field
- Use `validation` blocks to enforce input constraints:
  ```hcl
  variable "cidr_block" {
    description = "The CIDR block for the VPC"
    type        = string

    validation {
      condition     = can(cidrhost(var.cidr_block, 0))
      error_message = "Must be a valid IPv4 CIDR block."
    }
  }
  ```
- Provide sensible `default` values where appropriate
- Variables without defaults are required inputs — document this in the README

### Output Requirements

- Every output **must** have a `description` field
- Export all values that downstream consumers or other modules might need
- Use descriptive names matching the resource they expose (e.g., `vpc_id`, `public_subnet_ids`)

### Versioning

- Use **semantic versioning** via git tags: `v{MAJOR}.{MINOR}.{PATCH}`
  - MAJOR: Breaking changes (removed variables, renamed outputs, changed behavior)
  - MINOR: New features, new variables/outputs (backwards-compatible)
  - PATCH: Bug fixes (backwards-compatible)
- Consumers reference modules via git source URLs with version pins:
  ```hcl
  module "vpc" {
    source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/vpc?ref=v1.0.0"
  }
  ```
- **Document breaking changes** in the module's README under a Changelog or Migration section

### Tagging Strategy

All resources that support tags must include at minimum:

```hcl
tags = {
  Name        = "descriptive-resource-name"
  Environment = var.environment
  ManagedBy   = "opentofu"
}
```

Use the `tags` variable to allow consumers to add additional tags.

---

## Project Structure

```text
cloud-voyager-infra/
├── CLAUDE.md                        # This file — project conventions
├── docs/
│   ├── architecture/                # Per-module Mermaid diagrams
│   └── infracost-setup.md           # CI cost estimation setup guide
└── infra/
    ├── main.tf                      # Root configuration
    ├── variables.tf                 # Root variables
    ├── outputs.tf                   # Root outputs
    ├── providers.tf                 # AWS provider config
    ├── versions.tf                  # Version constraints
    └── modules/
        ├── vpc/                     # VPC + subnets + NAT + flow logs
        ├── security_groups/         # Tiered SGs (web/app/db/bastion)
        ├── alb/                     # Application Load Balancer + WAF
        ├── api_gateway/             # API Gateway v2 (HTTP API)
        ├── kms/                     # Customer-managed encryption keys
        ├── remote_state/            # S3 + DynamoDB state backend
        └── cloudwatch_alarms/       # SNS + alarms for observability
```

---

## Workflow

1. Create a feature branch from `main`
2. Make changes following the conventions above
3. Run `tofu fmt -recursive` and `tofu validate` before committing
4. Open a pull request against `main`
5. Tag releases with semantic versions when merging module changes
