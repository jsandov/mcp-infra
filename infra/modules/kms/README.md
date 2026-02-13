# KMS Module

Creates a customer-managed KMS key with automatic rotation, least-privilege key policies, and optional service access for CloudWatch Logs and S3 encryption.

Aligned with **FedRAMP** controls SC-12 (Key Management), SC-13 (Cryptographic Protection), and SC-28 (Protection at Rest).

## Usage

### Basic Key

```hcl
module "kms" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/kms?ref=v1.0.0"

  alias_name  = "infra-encryption"
  environment = "prod"

  tags = {
    Project = "my-project"
  }
}
```

### Key for CloudWatch Logs Encryption

```hcl
module "kms_logs" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/kms?ref=v1.0.0"

  alias_name                    = "logs-encryption"
  description                   = "KMS key for CloudWatch Logs encryption"
  environment                   = "prod"
  enable_cloudwatch_logs_access = true

  tags = {
    Project = "my-project"
  }
}
```

### Key for S3 State Bucket Encryption

```hcl
module "kms_state" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/kms?ref=v1.0.0"

  alias_name      = "state-encryption"
  description     = "KMS key for Terraform state encryption"
  environment     = "prod"
  enable_s3_access = true

  usage_principal_arns = [
    "arn:aws:iam::{AWS_ACCOUNT_ID}:role/GitHubActionsRole"
  ]

  tags = {
    Project = "my-project"
  }
}
```

## Inputs

| Name                            | Type           | Default                           | Required | Description                                    |
| ------------------------------- | -------------- | --------------------------------- | -------- | ---------------------------------------------- |
| `alias_name`                    | `string`       | —                                 | yes      | Alias name (prefixed with environment)         |
| `description`                   | `string`       | `Customer-managed encryption key` | no       | Key description                                |
| `environment`                   | `string`       | —                                 | yes      | Environment name (dev, staging, prod)          |
| `deletion_window_in_days`       | `number`       | `30`                              | no       | Days before permanent deletion (7-30)          |
| `admin_principal_arns`          | `list(string)` | `[]`                              | no       | IAM ARNs allowed to administer the key         |
| `usage_principal_arns`          | `list(string)` | `[]`                              | no       | IAM ARNs allowed to encrypt/decrypt            |
| `enable_cloudwatch_logs_access` | `bool`         | `false`                           | no       | Allow CloudWatch Logs service to use key       |
| `enable_s3_access`              | `bool`         | `false`                           | no       | Allow S3 service to use key                    |
| `tags`                          | `map(string)`  | `{}`                              | no       | Additional tags for all resources               |

## Outputs

| Name         | Description                               |
| ------------ | ----------------------------------------- |
| `key_id`     | The globally unique identifier for the key|
| `key_arn`    | The ARN of the KMS key                    |
| `alias_name` | The display name of the alias             |
| `alias_arn`  | The ARN of the alias                      |

## Security Features

- **Automatic rotation**: Key material rotated annually (FedRAMP SC-12)
- **Least-privilege policy**: Root account + optional admin/usage principals only
- **Service-scoped access**: CloudWatch Logs and S3 access gated by boolean toggles
- **Deletion protection**: Configurable waiting period (7-30 days) before permanent deletion
- **No wildcard principals**: Key policy never grants access to `*`

## FedRAMP Controls

| Control | Requirement                             | Implementation                        |
| ------- | --------------------------------------- | ------------------------------------- |
| SC-12   | Cryptographic key management            | Automatic annual rotation             |
| SC-13   | Cryptographic protection                | AWS KMS (FIPS 140-2 Level 2)          |
| SC-28   | Protection of information at rest       | Customer-managed encryption keys      |
