# KMS Module PRD

[Back to Overview](README.md)

## Purpose

Provide customer-managed KMS keys with automatic rotation, scoped admin/usage IAM principals, and service-level grants for CloudWatch Logs and S3.

## Requirements

### Key Management

- Customer-managed symmetric KMS key
- Automatic key rotation enabled
- Configurable deletion window (7-30 days)
- Key alias for human-readable identification

### Access Control

- Separate admin and usage IAM principal lists
- Admin principals: full key management (create, update, delete, policy)
- Usage principals: encrypt, decrypt, generate data key
- Key policy follows least-privilege principles

### Service Access

- CloudWatch Logs service grant for encrypted log groups
- S3 service grant for encrypted bucket objects
- Scoped via `kms:ViaService` condition keys

### Outputs

- Key ID, key ARN, alias ARN
- Key policy document (for reference)

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| SC-12 | Cryptographic key management | Automatic rotation; scoped admin principals |
| SC-13 | Cryptographic protection | AES-256 symmetric encryption |
| SC-28 | Data at rest | Customer-managed key for all encrypted resources |

## Status

Complete -- all requirements implemented and merged.

## Related Issues

- #30 — KMS module implementation
- #38 — Service access grants and policy refinements
