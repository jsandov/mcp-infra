# MCP Server Architecture

## 1. Request Flow

The primary request path from MCP client to Lambda function.

```mermaid
flowchart LR
    Client(["MCP Client"])
    WAF["WAF v2<br/>(optional)"]
    APIGW["API Gateway v2<br/>HTTP API"]
    Lambda["Lambda Function<br/>(Container Image)"]

    CF["CloudFront + WAF<br/>(recommended)"]

    Client -->|"HTTPS POST/GET/DELETE /mcp<br/>JSON-RPC 2.0"| CF
    CF --> APIGW
    APIGW -->|"AWS_PROXY<br/>payload v2.0"| Lambda
```

**Route mapping** (MCP spec 2025-03-26):

| Route | Purpose |
| --- | --- |
| `POST /mcp` | JSON-RPC requests and notifications |
| `GET /mcp` | SSE streaming endpoint |
| `DELETE /mcp` | Session termination |

---

## 2. Authentication

Cognito JWT authorization with internal or external user pools.

```mermaid
flowchart LR
    Client(["MCP Client"])

    subgraph Cognito["Cognito (choose one)"]
        Internal["Internal Pool<br/><i>aws_cognito_user_pool.this</i><br/>Created by module"]
        External["External Pool<br/><i>var.cognito_user_pool_id</i><br/>Bring your own"]
    end

    Authorizer["JWT Authorizer<br/><i>aws_apigatewayv2_authorizer</i><br/>scope: mcp/invoke"]
    APIGW["API Gateway v2"]

    Client -->|"client_credentials<br/>grant"| Cognito
    Cognito -->|"JWT access token"| Client
    Client -->|"Authorization: Bearer"| APIGW
    APIGW --> Authorizer
    Internal -.->|"issuer + audience"| Authorizer
    External -.->|"issuer + audience"| Authorizer
```

- **Internal pool**: Module creates Cognito user pool, domain, resource server, and client. Best for standalone deployments.
- **External pool**: Set `cognito_user_pool_id`, `cognito_user_pool_endpoint`, and `cognito_client_id`. Best for centralized identity planes.

---

## 3. Multi-Tenant Isolation

Hardware-level tenant isolation via Firecracker VMs and data partitioning.

```mermaid
flowchart TB
    APIGW["API Gateway v2<br/>Per-route throttle overrides"]

    subgraph Lambda["Lambda Function (enable_tenant_isolation = true)"]
        direction LR
        FCA["Firecracker VM<br/>Tenant A"]
        FCB["Firecracker VM<br/>Tenant B"]
        FCN["Firecracker VM<br/>Tenant N"]
    end

    subgraph DDB["DynamoDB Sessions"]
        direction TB
        TA["tenant_id=A | session_id=s1"]
        TB["tenant_id=B | session_id=s2"]
        TN["tenant_id=N | session_id=s3"]
    end

    GSI["GSI: session-id-index<br/>Hash: session_id"]

    APIGW -->|"tenant-id in JWT"| Lambda
    FCA -->|"scoped writes"| TA
    FCB -->|"scoped writes"| TB
    FCN -->|"scoped writes"| TN
    DDB --- GSI
```

- **Lambda**: `TenancyConfig.TenantIsolationMode = PER_TENANT` -- each tenant gets a dedicated Firecracker micro-VM. Immutable after creation.
- **DynamoDB**: Composite key `tenant_id` (hash) + `session_id` (range) enables `dynamodb:LeadingKeys` IAM conditions for row-level isolation.
- **API Gateway**: `route_throttle_overrides` map applies per-route rate/burst limits for noisy neighbor protection.

---

## 4. Encryption

Single KMS key encrypts all data at rest (SC-28).

```mermaid
flowchart TB
    KMS["KMS Customer Key<br/><i>var.kms_key_arn</i>"]

    LambdaEnv["Lambda Env Vars"]
    CWLogs["CloudWatch Logs<br/>(Lambda + API)"]
    DDB["DynamoDB Sessions"]
    ECR["ECR Repository"]
    SNS["SNS Alarm Topic"]

    KMS -.->|"encrypts"| LambdaEnv
    KMS -.->|"encrypts"| CWLogs
    KMS -.->|"encrypts"| DDB
    KMS -.->|"encrypts"| ECR
    KMS -.->|"encrypts"| SNS
```

---

## 5. Observability

CloudWatch alarms, X-Ray tracing, and structured logging.

```mermaid
flowchart LR
    Lambda["Lambda Function"]
    APIGW["API Gateway v2"]

    CWLambda["CloudWatch Logs<br/>/aws/lambda/..."]
    CWAPI["CloudWatch Logs<br/>/aws/apigateway/..."]
    XRay["X-Ray Tracing"]

    subgraph Alarms["CloudWatch Alarms (5)"]
        A1["Lambda Errors"]
        A2["Lambda Duration p99"]
        A3["Lambda Throttles"]
        A4["API 5xx Errors"]
        A5["API Latency p99"]
    end

    SNS["SNS Topic"]

    Lambda --> CWLambda
    Lambda --> XRay
    APIGW --> CWAPI
    CWLambda -.->|"metrics"| Alarms
    CWAPI -.->|"metrics"| Alarms
    Alarms -->|"notifications"| SNS
```

| Alarm | Metric | Threshold |
| --- | --- | --- |
| Lambda Errors | `Errors` Sum | > 5 per 5 min |
| Lambda Duration p99 | `Duration` p99 | > 80% of timeout |
| Lambda Throttles | `Throttles` Sum | > 5 per 5 min |
| API 5xx | `5xx` Sum | > 10 per 5 min |
| API Latency p99 | `Latency` p99 | > 90% of timeout |

---

## 6. Network & IAM

VPC placement and least-privilege IAM.

```mermaid
flowchart TB
    subgraph VPC["VPC -- var.vpc_id"]
        subgraph Subnets["Private Subnets"]
            Lambda["Lambda Function"]
        end
        SG["Security Groups<br/><i>var.vpc_security_group_ids</i>"]
    end

    IAM["IAM Role<br/><i>aws_iam_role.lambda</i>"]

    SG -.->|"ingress/egress rules"| Lambda
    Lambda -.->|"assumes"| IAM

    subgraph Policies["Attached Policies"]
        P1["AWSLambdaBasicExecutionRole"]
        P2["AWSLambdaVPCAccessExecutionRole"]
        P3["AWSXRayDaemonWriteAccess"]
        P4["KMS: Decrypt, DescribeKey, GenerateDataKey"]
        P5["DynamoDB: GetItem, PutItem, UpdateItem, DeleteItem, Query"]
    end

    IAM --- Policies
```

---

## FedRAMP Control Mapping

| Control | ID | Implementation |
| --- | --- | --- |
| Boundary Protection | SC-7 | VPC required, CloudFront + WAF recommended (WAFv2 not supported on HTTP API v2), security groups, tenant isolation via Firecracker VMs |
| Transmission Confidentiality | SC-8 | TLS on API Gateway, HTTPS-only |
| Cryptographic Key Management | SC-12/13 | KMS customer-managed key (required) |
| Encryption at Rest | SC-28 | KMS for env vars, logs, DynamoDB, ECR |
| Least Privilege | AC-6 | Scoped IAM role, no wildcard actions |
| Audit Logging | AU-2/3 | CloudWatch logs + API Gateway access logs |
| Monitoring | SI-4 | X-Ray tracing, 5 CloudWatch alarms |
| Incident Handling | IR-4 | SNS alarm notifications |
| Authentication | IA-2/8 | Cognito OAuth 2.0 JWT authorizer (internal or external pool) |
| Least Functionality | CM-7 | Reserved concurrency, timeouts, per-route throttling |
| Tenant Isolation | SC-7 | Firecracker VM per tenant when `enable_tenant_isolation = true` |

## Known Limitations

- **WAFv2 not supported on HTTP API v2**: The `aws_wafv2_web_acl_association` resource will fail at apply time if `waf_acl_arn` is provided. WAFv2 only supports REST APIs for API Gateway. Place a CloudFront distribution in front of the HTTP API and associate WAF with CloudFront instead.
- **30-second hard integration timeout**: HTTP API v2 has an immutable 30-second maximum integration timeout. This impacts the `GET /mcp` SSE streaming endpoint -- long-lived connections are forcibly closed. Mitigations: (1) polling/chunked-response pattern, (2) REST API with response streaming, or (3) Lambda Function URLs with `RESPONSE_STREAM` (incompatible with tenant isolation).
- **Lambda tenancy_config provider support**: GA AWS API feature but may not be supported in all `hashicorp/aws` provider versions. Verify against your pinned version.
- **DynamoDB LeadingKeys not enforced in IAM**: The IAM policy grants broad access without `dynamodb:LeadingKeys` conditions. True IAM-level tenant isolation requires per-invocation STS scoping via the token vending machine pattern.

## Design Decisions

- **Container-only deployment** -- MCP SDKs have large dependency trees; container images are the standard model
- **API Gateway v2 over ALB** -- Native JWT auth, structured logging, throttling, lower cost for serverless
- **VPC required** -- SC-7 boundary protection is mandatory for FedRAMP
- **Stateless by default** -- DynamoDB sessions optional; Streamable HTTP is inherently stateless
- **3 MCP routes** -- POST (requests), GET (SSE), DELETE (session termination) per spec 2025-03-26
- **Cognito client_credentials** -- Standard OAuth 2.0 for machine-to-machine MCP authentication
- **Tenant isolation mode** -- Hardware-level tenant isolation via Firecracker VMs; immutable after creation. Each tenant's MCP execution runs in a dedicated micro-VM for FedRAMP SC-7 boundary protection at the compute layer
- **External Cognito support** -- Allows centralized identity planes for organizations with existing Cognito user pools. Avoids per-deployment pool duplication and enables SSO across multi-tenant platforms
- **Composite DynamoDB key** -- When tenant isolation is enabled, sessions are partitioned by tenant_id for IAM-level isolation via `dynamodb:LeadingKeys`. Each tenant can only access their own session records
- **Per-route throttling** -- Route-level rate limits for noisy neighbor protection without impacting healthcheck or admin routes. Each route key (e.g., `POST /mcp`) can have independent rate and burst limits
