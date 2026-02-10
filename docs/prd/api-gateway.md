# API Gateway Module PRD

[Back to Overview](README.md)

## Purpose

Provide an HTTP API v2 (API Gateway) with access logging, throttling, CORS support, VPC Link integration, and optional WAF protection.

## Requirements

### API Gateway

- HTTP API v2 with configurable name and description
- Stage with auto-deploy enabled
- Access logging to CloudWatch Logs

### Throttling

- Configurable burst and rate limits at the stage level
- Default throttle settings with sensible limits

### CORS

- Configurable allowed origins, methods, and headers
- Optional CORS configuration (disabled by default)

### VPC Link

- Optional VPC Link for private integrations
- Configurable subnet IDs and security group IDs

### WAF

- Optional WAF v2 web ACL association
- Configurable via `waf_acl_arn` variable

### Outputs

- API ID, endpoint URL, stage name
- Log group name and ARN
- VPC Link ID (when enabled)

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| AC-6 | Least privilege | IAM-scoped access logging role |
| AU-2 | Audit events | Access logging to CloudWatch |
| AU-3 | Content of audit records | Structured JSON access logs |
| AU-9 | Protection of audit info | KMS-encrypted log group |
| SC-7 | Boundary protection | WAF integration; VPC Link for private backends |
| SC-8 | Transmission confidentiality | HTTPS-only API endpoint |
| SC-28 | Data at rest | KMS encryption on log group |
| SI-4 | System monitoring | Access logs enable traffic analysis |

## Status

Complete -- all requirements implemented and merged.

## Related Issues

- #25 — API Gateway module implementation
- #37 — WAF, CORS, and VPC Link enhancements
