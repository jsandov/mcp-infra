# API Gateway Architecture

```mermaid
flowchart LR
    Client(["Client"]) -->|"HTTPS"| API

    subgraph APIGW["API Gateway v2 (HTTP API)"]
        API["HTTP API<br/>Protocol: HTTP"]
        Stage["$default Stage<br/>Auto-deploy: true<br/>Throttling: rate + burst"]
    end

    API --> Stage

    Stage -->|"VPC Link<br/>(optional)"| Backend["Private Backend<br/>(in VPC)"]
    Stage -->|"public"| PublicBackend["Public Backend"]

    WAF["WAFv2 Web ACL<br/>(optional)"] -.->|"protects"| Stage
    CWLogs["CloudWatch Log Group<br/>Optional KMS encryption<br/>Retention: var.log_retention_days"] -.->|"access logs"| Stage

    subgraph CORS["CORS (optional)"]
        Origins["Allowed Origins"]
        Methods["Allowed Methods"]
        Headers["Allowed Headers"]
    end

    CORS -.->|"configures"| API
```

## Design Decisions

- **HTTP API v2**: Lower latency and cost vs REST API v1
- **Access logging**: Enabled by default with 90-day retention
- **Throttling**: Configurable rate and burst limits
- **VPC Link**: Optional private backend connectivity
- **No IAM role needed**: HTTP API v2 access logging works natively
