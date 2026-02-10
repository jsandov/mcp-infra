# Security Groups Module PRD

[Back to Overview](README.md)

## Purpose

Provide reusable, tiered security group patterns for common infrastructure tiers: web, application, database, and bastion.

## Requirements

### Security Group Tiers

| Tier | Ingress | Default |
| --- | --- | --- |
| Web | HTTP (80) and HTTPS (443) from internet | Enabled |
| Application | Configurable port, ingress only from web SG | Enabled |
| Database | Configurable port, ingress only from app SG | Enabled |
| Bastion | SSH (22) from allowed CIDRs | Disabled |

### Design

- Each tier independently toggleable
- All rules include descriptions for compliance auditing
- Port and CIDR input validations
- `name_prefix` + `create_before_destroy` lifecycle for zero-downtime replacement
- Optional restricted egress rules

### Outputs

- Security group IDs for each tier
- Security group ARNs for IAM policy references

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| AC-4 | Information flow enforcement | Layered ingress restricts traffic between tiers |
| SC-7 | Boundary protection | Bastion off by default; web tier is only internet-facing |

## Status

Complete -- all requirements implemented and merged.

## Related Issues

- #10 — Initial security groups module
- #27 — Restricted egress and enhancements
