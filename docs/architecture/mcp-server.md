# MCP Server Architecture

```mermaid
flowchart TB
    Client(["MCP Client<br/>(Claude Code, IDE, etc.)"])

    subgraph AWS["AWS Region (var.aws_region)"]

        subgraph Auth["Authentication (conditional)"]
            Cognito["Cognito User Pool<br/><i>aws_cognito_user_pool.this</i><br/>OAuth 2.0 client_credentials"]
        end

        subgraph Edge["Edge Protection"]
            WAF["WAF v2 Web ACL<br/>(conditional)"]
            APIGW["API Gateway v2 HTTP API<br/><i>aws_apigatewayv2_api.this</i><br/>POST /mcp | GET /mcp | DELETE /mcp"]
            APIStageLogs["Access Logs<br/><i>aws_cloudwatch_log_group.api</i>"]
        end

        subgraph VPC["VPC — var.vpc_id"]
            subgraph PrivateSubnets["Private Subnets — var.vpc_subnet_ids"]
                Lambda["Lambda Function<br/><i>aws_lambda_function.this</i><br/>Container Image | VPC | X-Ray"]
            end
            SG["Security Groups<br/>var.vpc_security_group_ids"]
        end

        subgraph Encryption["Encryption (SC-28)"]
            KMS["KMS Customer Key<br/>var.kms_key_arn"]
        end

        subgraph Storage["Storage (conditional)"]
            ECR["ECR Repository<br/><i>aws_ecr_repository.this</i><br/>KMS | Immutable Tags | Scan"]
            DDB["DynamoDB Sessions<br/><i>aws_dynamodb_table.sessions</i><br/>PAY_PER_REQUEST | TTL | PITR"]
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
    Client -.->|"JWT Token"| Cognito
    Cognito -.->|"Authorizer"| APIGW
    APIGW -->|"AWS_PROXY"| Lambda
    APIGW --> APIStageLogs

    Lambda --> CWLogs
    Lambda --> XRay
    Lambda -.->|"session state"| DDB
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
| Boundary Protection | SC-7 | VPC required, WAF optional, security groups |
| Transmission Confidentiality | SC-8 | TLS on API Gateway, HTTPS-only |
| Cryptographic Key Management | SC-12/13 | KMS customer-managed key (required) |
| Encryption at Rest | SC-28 | KMS for env vars, logs, DynamoDB, ECR |
| Least Privilege | AC-6 | Scoped IAM role, no wildcard actions |
| Audit Logging | AU-2/3 | CloudWatch logs + API Gateway access logs |
| Monitoring | SI-4 | X-Ray tracing, 5 CloudWatch alarms |
| Incident Handling | IR-4 | SNS alarm notifications |
| Authentication | IA-2/8 | Cognito OAuth 2.0 JWT authorizer |
| Least Functionality | CM-7 | Reserved concurrency, timeouts |

## Design Decisions

- **Container-only deployment** -- MCP SDKs have large dependency trees; container images are the standard model
- **API Gateway v2 over ALB** -- Native JWT auth, structured logging, throttling, lower cost for serverless
- **VPC required** -- SC-7 boundary protection is mandatory for FedRAMP
- **Stateless by default** -- DynamoDB sessions optional; Streamable HTTP is inherently stateless
- **3 MCP routes** -- POST (requests), GET (SSE), DELETE (session termination) per spec 2025-03-26
- **Cognito client_credentials** -- Standard OAuth 2.0 for machine-to-machine MCP authentication
