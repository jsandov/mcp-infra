# Remote State Architecture

```mermaid
flowchart LR
    CI["CI/CD<br/>(GitHub Actions)"] -->|"tofu plan/apply"| S3
    Dev["Developer<br/>(local)"] -->|"tofu plan/apply"| S3

    subgraph Backend["Remote State Backend"]
        S3["S3 Bucket<br/>Versioning: enabled<br/>Encryption: AES-256 or KMS<br/>Public access: blocked"]
        DDB["DynamoDB Table<br/>Key: LockID<br/>Billing: PAY_PER_REQUEST<br/>PITR: enabled"]
        BucketPolicy["Bucket Policy<br/>Deny non-SSL<br/>Optional principal restriction"]
    end

    S3 -.->|"state locking"| DDB
    BucketPolicy --> S3

    S3 -->|"access logs<br/>(optional)"| LogsBucket["S3 Logs Bucket"]
    S3 -->|"noncurrent versions<br/>expire after N days"| Lifecycle["Lifecycle Policy"]
```

## Design Decisions

- **SSL enforced**: Bucket policy denies all non-HTTPS requests
- **Versioning**: State files versioned for rollback capability
- **Public access fully blocked**: All four S3 public access block settings enabled
- **Point-in-time recovery**: DynamoDB PITR for lock table disaster recovery
- **PAY_PER_REQUEST**: Avoids DynamoDB capacity planning overhead
- **Noncurrent version expiration**: Defaults to 90 days to limit storage cost
