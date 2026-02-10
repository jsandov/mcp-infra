# CI/CD Module PRD

[Back to Overview](README.md)

## Purpose

Provide GitHub Actions workflows for automated OpenTofu plan, cost estimation, and security scanning on every pull request.

## Requirements

### OpenTofu Plan

- Set up OpenTofu v1.11.0 via `opentofu/setup-opentofu`
- Run `tofu init`, `tofu fmt -check -recursive`, `tofu validate`, and `tofu plan`
- Post plan summary as a PR comment
- Triggered on PRs targeting `main` when `infra/**` files change

### Cost Estimation

- Infracost integration for cost breakdown
- Compare baseline (main) vs PR branch costs
- Post cost diff as PR comment

### Security Scanning

- **TFLint** for OpenTofu linting and best practices
- **Trivy** for misconfiguration and vulnerability scanning
- **Checkov** for compliance policy checks
- All scanners run on every PR

### Authentication

- OIDC-based AWS authentication (no long-lived credentials)
- GitHub Actions OIDC provider configured in AWS
- IAM role with scoped permissions for `tofu plan`

### Supply Chain Security

- All GitHub Actions pinned to exact SHA versions
- Dependabot or Renovate for action version updates

### Outputs

- PR comments with plan, cost, and scan results
- Workflow status checks as merge gates

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| SA-11 | Developer security testing | Trivy + Checkov scan on every PR |
| CM-3 | Configuration change control | Plan + review before any apply |
| IA-2 | Identification and authentication | OIDC auth, no long-lived secrets |
| SC-8 | Transmission confidentiality | HTTPS for all GitHub/AWS API calls |

## Status

Complete -- all requirements implemented and merged.

## Related Issues

- #12 — Initial CI workflow with plan and Infracost
- #23 — OIDC auth and security scanning (TFLint, Trivy, Checkov)
- #40 — Action version pinning
