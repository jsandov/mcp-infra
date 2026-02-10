# MCP Server Architecture

```mermaid
flowchart TB
    Client(["MCP Client<br/>(Claude Code, IDE, etc.)"])

    subgraph AWS["AWS Region (var.aws_region)"]

        subgraph Auth["Authentication (conditional)"]
            CognitoInt["Internal Cognito User Pool<br/><i>aws_cognito_user_pool.this</i><br/>OAuth 2.0 client_credentials"]
            CognitoExt["External Cognito User Pool<br/><i>var.cognito_user_pool_id</i><br/>Centralized identity plane"]
        end

        subgraph Edge["Edge Protection"]
            WAF["WAF v2 Web ACL<br/>(conditional)"]
            APIGW["API Gateway v2 HTTP API<br/><i>aws_apigatewayv2_api.this</i><br/>POST /mcp | GET /mcp | DELETE /mcp<br/>Per-route throttle overrides"]
            APIStageLogs["Access Logs<br/><i>aws_cloudwatch_log_group.api</i>"]
        end

        subgraph VPC["VPC — var.vpc_id"]
            subgraph PrivateSubnets["Private Subnets — var.vpc_subnet_ids"]
                Lambda["Lambda Function<br/><i>aws_lambda_function.this</i><br/>Container Image | VPC | X-Ray"]
                subgraph TenantIsolation["Tenant Isolation (conditional, SC-7)"]
                    FC1["Firecracker VM<br/>Tenant A"]
                    FC2["Firecracker VM<br/>Tenant B"]
                    FCn["Firecracker VM<br/>Tenant N"]
                end
            end
            SG["Security Groups<br/>var.vpc_security_group_ids"]
        end

        subgraph Encryption["Encryption (SC-28)"]
            KMS["KMS Customer Key<br/>var.kms_key_arn"]
        end

        subgraph Storage["Storage (conditional)"]
            ECR["ECR Repository<br/><i>aws_ecr_repository.this</i><br/>KMS | Immutable Tags | Scan"]
            DDB["DynamoDB Sessions<br/><i>aws_dynamodb_table.sessions</i><br/>PAY_PER_REQUEST | TTL | PITR<br/>Composite key: tenant_id + session_id"]
        end

        subgraph Observability["Monitoring (SI-4)"]
            CWLogs["CloudWatch Logs<br/><i>aws_cloudwatch_log_group.lambda</i><br/>KMS Encrypted"]
            XRay["X-Ray Tracing"]
            Alarms["CloudWatch Alarms (5)<br/>Errors | Duration | Throttles<br/>5xx | Latency"]
            SNS["SNS Topic<br/><i>aws_sns_topic.alarms</i><br/>KMS Encrypted"]
        end

        IAM["IAM Role<br/><i>aws_iam_role.lambda</i><br/>Least Privilege (AC-6)"]
    end

    Client -->|"HTTPS POST<br/>JSON-RPC 2.0"| WAF
    WAF --> APIGW
    Client -.->|"JWT Token"| CognitoInt
    Client -.->|"JWT Token<br/>(external pool)"| CognitoExt
    CognitoInt -.->|"Authorizer"| APIGW
    CognitoExt -.->|"Authorizer<br/>(dashed = external)"| APIGW
    APIGW -->|"AWS_PROXY"| Lambda
    APIGW --> APIStageLogs

    Lambda -->|"tenant isolation"| TenantIsolation
    Lambda --> CWLogs
    Lambda --> XRay
    Lambda -.->|"session state<br/>(tenant_id + session_id)"| DDB
    Lambda -.->|"assumes"| IAM

    ECR -.->|"image source"| Lambda

    KMS -.->|"encrypts"| CWLogs
    KMS -.->|"encrypts"| Lambda
    KMS -.->|"encrypts"| DDB
    KMS -.->|"encrypts"| ECR
    KMS -.->|"encrypts"| SNS
    KMS -.->|"encrypts"| APIStageLogs

    SG -.->|"controls"| Lambda

    Alarms -->|"notifications"| SNS
    CWLogs -.->|"metrics"| Alarms
```

## FedRAMP Control Mapping

| Control | ID | Implementation |
| --- | --- | --- |
| Boundary Protection | SC-7 | VPC required, WAF optional, security groups, tenant isolation via Firecracker VMs |
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
