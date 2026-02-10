# Remote State Module PRD

[Back to Overview](README.md)

## Purpose

Provide an S3 backend and DynamoDB table for secure OpenTofu remote state management with encryption, locking, and access control.

## Requirements

### S3 State Bucket

- Server-side encryption (AES-256 or KMS)
- Versioning enabled for state recovery
- Block all public access
- SSL-only access enforcement via bucket policy
- Access logging to a separate logging bucket

### DynamoDB Lock Table

- Table for state locking to prevent concurrent modifications
- Point-in-time recovery (PITR) enabled
- Pay-per-request billing mode

### Access Control

- IAM principal restriction via bucket policy
- Configurable list of authorized IAM ARNs
- Deny all access except from specified principals

### Lifecycle

- Configurable lifecycle rules for noncurrent object versions
- Default expiration for old state versions

### Outputs

- Bucket name, bucket ARN
- DynamoDB table name, table ARN
- Backend configuration snippet for consumers

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| SC-8 | Transmission confidentiality | SSL-only bucket policy |
| SC-28 | Data at rest | Server-side encryption on bucket and table |
| AU-2 | Audit events | Access logging to dedicated logging bucket |
| AC-6 | Least privilege | IAM principal restriction on bucket policy |

## Status

Complete -- all requirements implemented and merged.

## Related Issues

- #22 — Remote state module implementation
- #28 — Encryption and access control enhancements
- #41 — Lifecycle rules and PITR
