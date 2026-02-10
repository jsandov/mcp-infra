# Remote State Module

Provisions an S3 bucket and DynamoDB table for OpenTofu remote state management with encryption, versioning, and state locking.

## Usage

```hcl
module "remote_state" {
  source = "git::https://github.com/<org>/mcp-infra.git//infra/modules/remote_state?ref=v1.0.0"

  bucket_name     = "my-org-terraform-state"
  lock_table_name = "terraform-state-lock"
  environment     = "prod"

  tags = {
    Project = "my-project"
  }
}
```

After applying, copy the `backend_config` output into your `versions.tf` and run `tofu init -migrate-state`.

## Inputs

| Name                                | Type          | Default                  | Required | Description                                      |
| ----------------------------------- | ------------- | ------------------------ | -------- | ------------------------------------------------ |
| `bucket_name`                       | `string`      | —                        | yes      | S3 bucket name for state storage                 |
| `lock_table_name`                   | `string`      | `terraform-state-lock`   | no       | DynamoDB table name for state locking            |
| `environment`                       | `string`      | —                        | yes      | Environment name (dev, staging, prod)            |
| `noncurrent_version_expiration_days`| `number`      | `90`                     | no       | Days before old state versions are deleted       |
| `tags`                              | `map(string)` | `{}`                     | no       | Additional tags for all resources                |

## Outputs

| Name              | Description                                        |
| ----------------- | -------------------------------------------------- |
| `bucket_id`       | The name of the S3 state bucket                    |
| `bucket_arn`      | The ARN of the S3 state bucket                     |
| `lock_table_name` | The name of the DynamoDB lock table                |
| `lock_table_arn`  | The ARN of the DynamoDB lock table                 |
| `backend_config`  | Ready-to-paste backend configuration block         |

## Security Features

- **Encryption at rest**: AES-256 server-side encryption with bucket key
- **Versioning**: All state files versioned for rollback capability
- **Public access blocked**: All four public access block settings enabled
- **Lifecycle management**: Noncurrent versions expire after configurable days (default 90)
- **On-demand billing**: DynamoDB uses PAY_PER_REQUEST to avoid over-provisioning
