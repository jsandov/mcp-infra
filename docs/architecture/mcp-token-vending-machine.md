# MCP Token Vending Machine Architecture

```mermaid
flowchart LR
    Client(["MCP Client<br/>(Claude Code, IDE, etc.)"])

    subgraph AWS["AWS Region"]

        subgraph Auth["Authentication"]
            Cognito["Cognito User Pool<br/>JWT with tenant_id claim"]
        end

        subgraph Edge["Edge Protection"]
            APIGW["API Gateway v2<br/>JWT Authorizer"]
        end

        subgraph Compute["Compute"]
            Lambda["MCP Server Lambda<br/><i>aws_lambda_function</i><br/>Extracts tenant_id from JWT"]
        end

        subgraph TVM["Token Vending Machine"]
            STS["STS AssumeRole<br/><i>sts:AssumeRole</i><br/>Session tags: tenant_id"]
            PermBoundary["Permission Boundary<br/>(ceiling policy)<br/>Restricts max permissions"]
            TenantRole["Tenant IAM Role<br/><i>arn:aws:iam::*:role/mcp-tenant-*</i><br/>Scoped to tenant resources"]
        end

        subgraph TenantResources["Tenant Resources (scoped by tenant_id)"]
            S3["S3 Bucket<br/>s3:prefix = tenant_id/*"]
            DDB["DynamoDB Table<br/>dynamodb:LeadingKeys = tenant_id"]
            Secrets["Secrets Manager<br/>secretsmanager:ResourceTag/tenant_id"]
        end

        subgraph Encryption["Encryption"]
            KMS["KMS Customer Key<br/>var.kms_key_arn"]
        end
    end

    Client -->|"HTTPS + JWT"| APIGW
    Client -.->|"JWT Token"| Cognito
    Cognito -.->|"Authorizer"| APIGW
    APIGW -->|"AWS_PROXY"| Lambda

    Lambda -->|"1. Extract tenant_id<br/>from JWT claims"| STS
    STS -->|"2. AssumeRole with<br/>session tag: tenant_id"| TenantRole
    TenantRole -->|"3. Constrained by"| PermBoundary

    TenantRole -->|"4. Scoped access"| S3
    TenantRole -->|"4. Scoped access"| DDB
    TenantRole -->|"4. Scoped access"| Secrets

    KMS -.->|"encrypts"| S3
    KMS -.->|"encrypts"| DDB
    KMS -.->|"encrypts"| Secrets
```

## FedRAMP Control Mapping

| Control | ID | Implementation |
| --- | --- | --- |
| Least Privilege | AC-6 | STS session tags scope credentials to tenant_id; permission boundary caps max permissions |
| Account Management | AC-2 | Tenant roles are template-based; no standing credentials; short-lived STS tokens |
| Boundary Protection | SC-7 | IAM policy conditions enforce tenant isolation at the resource level |
| Cryptographic Key Management | SC-12/13 | KMS customer-managed key encrypts all tenant resources |
| Audit Logging | AU-2/3 | CloudTrail records all STS AssumeRole calls with session tags |

## Design Decisions

- **STS AssumeRole with session tags** -- The TVM uses `sts:AssumeRole` with `tenant_id` as a session tag rather than creating per-tenant IAM users. This provides short-lived, scoped credentials without credential management overhead
- **Permission boundaries as ceilings** -- Permission boundaries define the maximum permissions any tenant role can have, preventing privilege escalation even if the role policy is misconfigured
- **Template tenant roles** -- Tenant roles use IAM policy variables (`${aws:PrincipalTag/tenant_id}`) to scope access dynamically. A single role definition serves all tenants without per-tenant role creation
- **Zero-trust multi-tenancy** -- Every tenant credential is independently scoped. No tenant can access another tenant's resources even if they obtain the other tenant's role ARN, because session tags are set by the trusted Lambda (not the caller)
- **Role ARN pattern matching** -- `tenant_role_arn_pattern` uses wildcards to allow the Lambda to assume any matching tenant role while preventing assumption of unrelated roles
- **No standing credentials** -- STS tokens expire automatically (default 1 hour). There are no long-lived access keys to rotate or revoke
