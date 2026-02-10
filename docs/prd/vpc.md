# VPC Module PRD

[Back to Overview](README.md)

## Purpose

Provide a production-ready VPC with public and private subnets, Internet Gateway, optional NAT Gateway, VPC Flow Logs, and security hardening of default resources.

## Requirements

### Networking

- Configurable CIDR block with validation
- Public and private subnets across multiple AZs (1-6)
- Internet Gateway for public subnets
- NAT Gateway for private subnets (toggleable via `enable_nat_gateway`)
- DNS support and hostnames enabled

### Default Resource Hardening

- `aws_default_security_group` with no ingress/egress rules (deny-all)
- `aws_default_network_acl` with no rules (deny-all)
- `aws_default_route_table` with no routes

### VPC Flow Logs

- `aws_flow_log` capturing all traffic (accept + reject)
- CloudWatch Logs destination with configurable retention
- IAM role with least-privilege policy for flow log delivery
- Enabled by default (`enable_flow_logs = true`)

### Input Validations

- `environment`: must be one of `dev`, `staging`, `prod`
- `public_subnet_cidrs`: at least one CIDR required
- `private_subnet_cidrs`: at least one CIDR required
- `availability_zones`: between 1 and 6 AZs
- `flow_log_retention_days`: must be a valid CloudWatch retention value

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| AU-2 | Audit events | VPC Flow Logs capture all traffic |
| SC-7 | Boundary protection | Default deny-all on SG, NACL, route table |
| SC-28 | Data at rest | KMS encryption for flow log group |

## Status

Complete -- all requirements implemented and merged.

## Related Issues

- #9 — VPC Flow Logs
- #13 — VPC hardening (default resources)
- #26 — IAM scoping for flow log role
- #39 — README update
