# KMS Architecture

```mermaid
flowchart TB
    subgraph KMS["Customer-Managed KMS Key"]
        Key["KMS Key<br/>Auto-rotation: annual<br/>Deletion window: 7-30 days"]
        Alias["Key Alias<br/>alias/$env-$name"]
    end

    subgraph Policy["Key Policy"]
        Root["Root Account Access<br/>(prevents unmanageable key)"]
        Admin["Admin Principals<br/>(optional)"]
        Usage["Usage Principals<br/>(encrypt/decrypt)"]
        CWLogs["CloudWatch Logs Service<br/>(optional, scoped by account+region)"]
        S3["S3 Service<br/>(optional, scoped by CallerAccount)"]
    end

    Policy --> Key
    Key --> Alias

    CWLogs -.->|"encrypts"| LogGroups["CloudWatch Log Groups"]
    S3 -.->|"encrypts"| Buckets["S3 Buckets"]
    Usage -.->|"encrypt/decrypt"| Data["Application Data"]
```

## Design Decisions

- **Automatic rotation**: Key material rotated annually (FedRAMP SC-12)
- **Root account access**: Required to prevent key from becoming unmanageable
- **Service-scoped access**: CloudWatch and S3 access gated by boolean toggles
- **CallerAccount condition**: S3 policy restricts to same-account usage only
- **No wildcard principals**: Key policy never grants access to `*`
