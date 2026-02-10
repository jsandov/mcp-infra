# PRD: mcp-infra Repository Bootstrap

## Overview

Bootstrap the `mcp-infra` repository as an OpenTofu infrastructure-as-code project targeting AWS. The repo will house reusable infrastructure modules designed to be versioned and consumed by other repositories.

## Goals

- Establish a secure, well-documented IaC repository with clear conventions
- Start simple with a VPC module and flat structure
- Enable module versioning for cross-repo consumption
- Provide guardrails via CLAUDE.md and .gitignore from day one

---

## Feature 1: CLAUDE.md — Project Conventions and Security Practices

**Status: Complete** (PR #1, merged)

### Feature 1 Purpose

Provide a committed project-level configuration file that guides contributors (and AI assistants) on best practices, coding standards, and security requirements for this IaC repo.

### Feature 1 Requirements

- **OpenTofu/HCL conventions**
  - File naming: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`
  - Variable and output naming conventions (snake_case, descriptive)
  - Module structure expectations (inputs, outputs, README per module)
  - Formatting: `tofu fmt` must pass before commit
  - Validation: `tofu validate` must pass before commit

- **Security practices**
  - **Secret management**: No hardcoded secrets in `.tf` files. Use AWS Secrets Manager or SSM Parameter Store. Never commit `.tfvars` files containing sensitive values.
  - **IAM least privilege**: No wildcard (`*`) actions or resources in IAM policies. All IAM roles must follow least-privilege principles. Prefer managed policies where appropriate.
  - **State file security**: State files must never be committed to git. When remote state is configured, require encryption at rest (S3 SSE) and state locking (DynamoDB). Restrict state bucket access via IAM policies.
  - **Provider constraints**: Pin provider versions. Never use `>=` without an upper bound.

- **Module authoring guidelines**
  - Every module must have: `variables.tf`, `outputs.tf`, `main.tf`, and a `README.md`
  - Use semantic versioning via git tags (e.g., `v1.0.0`)
  - Document breaking changes in module READMEs
  - All variables must have `description` and `type` defined
  - Use `validation` blocks for input constraints where applicable

---

## Feature 2: .gitignore — Repository Hygiene

**Status: Complete** (PR #2, merged)

### Feature 2 Purpose

Prevent sensitive, generated, and user-specific files from being committed.

### Feature 2 Requirements

- **OpenTofu / Terraform specific**
  - `.terraform/` — provider plugins and module cache
  - `*.tfstate` and `*.tfstate.*` — state files
  - `*.tfvars` — may contain secrets (except example files)
  - `.terraform.lock.hcl` — optional, can be committed for reproducibility (decision: ignore for now, revisit when pinning matters)
  - `crash.log` — OpenTofu crash logs
  - `override.tf` and `override.tf.json` — local overrides
  - `*_override.tf` and `*_override.tf.json` — local overrides

- **Claude Code specific**
  - `.claude/` — user-specific settings (settings.json, etc.)
  - Do NOT ignore `CLAUDE.md` — it is committed and shared

- **General**
  - `.DS_Store` (macOS)
  - `*.swp`, `*.swo` (vim)
  - `.idea/`, `.vscode/` (IDE settings)
  - `*.env` and `.env*` (environment files)

---

## Feature 3: Infrastructure Folder — OpenTofu + AWS

**Status: Complete** (PR #3, merged)

### Feature 3 Purpose

Create the initial infrastructure directory structure with a VPC module as the first provisioned resource.

### Feature 3 Requirements

- **Structure** (flat, simple)

  ```text
  infra/
  ├── modules/
  │   └── vpc/
  │       ├── main.tf
  │       ├── variables.tf
  │       ├── outputs.tf
  │       └── README.md
  ├── main.tf          # Root config — calls modules
  ├── variables.tf     # Root-level variables
  ├── outputs.tf       # Root-level outputs
  ├── providers.tf     # AWS provider config
  └── versions.tf      # OpenTofu and provider version constraints
  ```

- **VPC module scope**
  - Configurable CIDR block
  - Public and private subnets across multiple AZs
  - Internet Gateway for public subnets
  - NAT Gateway for private subnets (toggleable via variable)
  - DNS support and hostnames enabled
  - Tagging strategy: `Name`, `Environment`, `ManagedBy = "opentofu"`

- **Provider and version constraints**
  - Require OpenTofu `>= 1.6.0, < 2.0.0`
  - AWS provider pinned to a specific minor version range
  - AWS region configurable via variable

- **State management**
  - Start with local state (no backend block)
  - Include commented-out S3 backend example with notes on migration

---

## Feature 4: GitHub Actions — OpenTofu Plan + Infracost

**Status: In Progress**

### Feature 4 Purpose

Automate infrastructure validation and cost estimation on pull requests. Every PR that changes `infra/` files triggers `tofu plan` and posts an Infracost cost breakdown as a PR comment.

### Feature 4 Requirements

- **Workflow trigger**
  - Pull requests targeting `main` only
  - Path filter: only runs when `infra/**` files are changed

- **OpenTofu Plan job**
  - Set up OpenTofu v1.6.x via `opentofu/setup-opentofu@v1`
  - Configure AWS credentials from GitHub secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
  - Run `tofu init` in `infra/` directory
  - Run `tofu fmt -check -recursive` (enforces CLAUDE.md convention)
  - Run `tofu validate`
  - Run `tofu plan` and capture output
  - Post plan summary as a PR comment

- **Infracost job**
  - Set up Infracost via `infracost/actions/setup@v3`
  - Parse HCL directly (no plan JSON needed)
  - Generate baseline cost from `main` branch
  - Generate current cost from PR branch
  - Run `infracost diff` to compare
  - Post cost breakdown as PR comment (behavior: `update`)

- **Required GitHub secrets**
  - `AWS_ACCESS_KEY_ID` — AWS credentials for `tofu plan`
  - `AWS_SECRET_ACCESS_KEY` — AWS credentials for `tofu plan`
  - `INFRACOST_API_KEY` — Infracost API authentication (free tier)

- **Setup documentation**
  - How to obtain a free Infracost API key
  - How to configure all three GitHub secrets
  - Recommended IAM policy for the CI user (read-only)

---

## Module Versioning Strategy (Recommendation)

### Approach: Git Tags + Source URLs

This is the simplest approach that requires no additional infrastructure.

**How it works:**

1. Develop modules in `infra/modules/`
2. Tag releases with semantic versions: `git tag -a v1.0.0 -m "Initial VPC module"`
3. Consumers reference modules via git source URLs:

   ```hcl
   module "vpc" {
     source = "git::https://github.com/<org>/mcp-infra.git//infra/modules/vpc?ref=v1.0.0"
   }
   ```

**Benefits:**

- Zero additional infrastructure or tooling
- Works immediately with any git host
- Semantic versioning provides clear compatibility signals
- Consumers pin to specific versions and upgrade intentionally

**Future migration path:**

- If module count grows significantly, consider extracting modules into dedicated repos or publishing to a private registry

---

## Implementation Approach

Each feature is implemented on a **separate branch** using **git worktrees** for isolation. Parallel subagents are used where tasks are independent:

| Feature                        | Branch                 | Status    |
| ------------------------------ | ---------------------- | --------- |
| CLAUDE.md                      | `feature/claude-md`    | Merged    |
| .gitignore                     | `feature/gitignore`    | Merged    |
| Infrastructure folder          | `feature/infra-vpc`    | Merged    |
| Architecture diagram           | `feature/infra-diagram`| Merged    |
| PRD update                     | `feature/prd-update`   | In Progress |
| CI workflow + Infracost        | `feature/ci-infracost` | In Progress |

---

## Out of Scope (for now)

- Remote state backend setup (S3 + DynamoDB)
- `tofu apply` automation (CI runs plan only, apply is manual)
- Additional AWS resources beyond VPC
- Private module registry
- Terratest or other IaC testing frameworks

---

## Success Criteria

- [x] `CLAUDE.md` committed with security and convention guidance
- [x] `.gitignore` covers all OpenTofu, Claude Code, and general patterns
- [x] `infra/` directory with working VPC module structure
- [x] `tofu fmt` and `tofu validate` pass on all `.tf` files
- [x] Module is consumable via git source URL pattern
- [x] Architecture diagram documents VPC topology
- [ ] GitHub Actions workflow runs `tofu plan` on PRs
- [ ] Infracost posts cost breakdown as PR comment
- [ ] Setup documentation for required secrets and API keys
