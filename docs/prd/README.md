# mcp-infra — Product Requirements Overview

## Project Overview

`mcp-infra` is an OpenTofu infrastructure-as-code repository targeting AWS. It houses reusable, versioned infrastructure modules designed to be consumed by other repositories via git source URLs.

## Goals and Principles

- **Security first** — FedRAMP-aligned controls baked into every module
- **Reusability** — Modules are self-contained with clear inputs, outputs, and documentation
- **Simplicity** — Flat structure, minimal dependencies, sensible defaults
- **Automation** — CI validates every PR with plan, cost, and security scanning
- **Versioning** — Semantic versioning via git tags for safe cross-repo consumption

## Module Inventory

| Module | PRD | Status |
| --- | --- | --- |
| VPC | [vpc.md](vpc.md) | Complete |
| Security Groups | [security-groups.md](security-groups.md) | Complete |
| ALB | [alb.md](alb.md) | Complete |
| API Gateway | [api-gateway.md](api-gateway.md) | Complete |
| KMS | [kms.md](kms.md) | Complete |
| Remote State | [remote-state.md](remote-state.md) | Complete |
| CloudWatch Alarms | [cloudwatch-alarms.md](cloudwatch-alarms.md) | In Progress |
| CI/CD | [ci-cd.md](ci-cd.md) | Complete |

## Project-Wide Conventions

All modules follow the conventions defined in [CLAUDE.md](../../CLAUDE.md), including:

- File naming: `main.tf`, `variables.tf`, `outputs.tf`, `README.md` per module
- `snake_case` naming for all identifiers
- Every variable must have `description`, `type`, and `validation` where applicable
- Every output must have a `description`
- `tofu fmt` and `tofu validate` must pass before every commit
- No hardcoded secrets; use AWS Secrets Manager or SSM Parameter Store
- IAM least privilege — no wildcard actions or resources

## Module Versioning Strategy

Modules use **git tags with semantic versioning**:

1. Develop modules in `infra/modules/`
2. Tag releases: `git tag -a v1.0.0 -m "Release description"`
3. Consumers reference via git source URLs:

```hcl
module "vpc" {
  source = "git::https://github.com/<org>/mcp-infra.git//infra/modules/vpc?ref=v1.0.0"
}
```

- MAJOR: Breaking changes (removed variables, renamed outputs)
- MINOR: New features, new variables/outputs (backwards-compatible)
- PATCH: Bug fixes (backwards-compatible)

## Repository Structure

```text
mcp-infra/
├── CLAUDE.md                  # Project conventions and security practices
├── docs/
│   ├── prd.md                 # Original monolithic PRD (legacy)
│   └── prd/                   # Per-module PRDs (current)
│       ├── README.md           # This file
│       ├── vpc.md
│       ├── security-groups.md
│       ├── alb.md
│       ├── api-gateway.md
│       ├── kms.md
│       ├── remote-state.md
│       ├── cloudwatch-alarms.md
│       └── ci-cd.md
└── infra/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf
    ├── versions.tf
    └── modules/
        ├── vpc/
        ├── security_groups/
        ├── alb/
        ├── api_gateway/
        ├── kms/
        └── remote_state/
```
