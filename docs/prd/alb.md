# ALB Module PRD

[Back to Overview](README.md)

## Purpose

Provide an Application Load Balancer with HTTPS support, WAF integration, health checks, access logging, and deletion protection.

## Requirements

### Load Balancer

- HTTP listener (port 80) with redirect to HTTPS
- HTTPS listener (port 443) with ACM certificate
- TLS 1.3 minimum security policy
- Deletion protection enabled by default
- Drop invalid HTTP headers

### WAF Integration

- Optional WAF v2 web ACL association
- Configurable via `waf_acl_arn` variable

### Access Logging

- S3 bucket for ALB access logs
- Server-side encryption on log bucket
- Lifecycle policy for log retention

### Health Checks

- Configurable health check path, interval, and thresholds
- Target group with configurable port and protocol

### Outputs

- ALB ARN, DNS name, hosted zone ID
- Target group ARN
- Listener ARNs (HTTP and HTTPS)

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| SC-7 | Boundary protection | Drop invalid headers; WAF integration |
| SC-8 | Transmission confidentiality | TLS 1.3 enforced on HTTPS listener |
| AU-2 | Audit events | Access logs to encrypted S3 bucket |

## Status

Complete -- all requirements implemented and merged.

## Related Issues

- #14 — ALB module implementation
- #29 — WAF and access logging enhancements
