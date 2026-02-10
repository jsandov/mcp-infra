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

Each feature should be implemented on a **separate branch** using **git worktrees** for isolation. Use **parallel subagents** where tasks are independent:

| Feature               | Branch               | Notes                          |
| --------------------- | -------------------- | ------------------------------ |
| CLAUDE.md             | `feature/claude-md`  | Can be developed independently |
| .gitignore            | `feature/gitignore`  | Can be developed independently |
| Infrastructure folder | `feature/infra-vpc`  | Can be developed independently |

All three branches are independent and can be worked on in parallel using worktrees and subagents. Each branch should be merged to `main` via PR.

---

## Out of Scope (for now)

- Remote state backend setup (S3 + DynamoDB)
- CI/CD pipeline for `tofu plan` / `tofu apply`
- Additional AWS resources beyond VPC
- Private module registry
- Terratest or other IaC testing frameworks

---

## Success Criteria

- [ ] `CLAUDE.md` committed with security and convention guidance
- [ ] `.gitignore` covers all OpenTofu, Claude Code, and general patterns
- [ ] `infra/` directory with working VPC module structure
- [ ] `tofu fmt` and `tofu validate` pass on all `.tf` files
- [ ] Module is consumable via git source URL pattern
