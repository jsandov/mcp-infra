# MCP Server Module

A production-ready, FedRAMP-compliant OpenTofu module that deploys a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server on AWS Lambda behind API Gateway v2. Designed for secure, scalable AI tool serving with built-in authentication, encryption, and continuous monitoring.

## Architecture

```
MCP Client (Claude Code, Cursor, etc.)
    |  HTTPS POST/GET/DELETE /mcp (JSON-RPC 2.0)
    v
+-------------------+
| WAF v2 (optional) |  Rate limiting + IP filtering (SC-7)
+-------------------+
    |
    v
+---------------------------+
| API Gateway v2 HTTP API   |
|  - Cognito JWT Auth (IA-2)|  
|  - Access logging (AU-2)  |  
|  - Throttling (CM-7)      |  
|  - CORS: Mcp-Session-Id   |
+---------------------------+
    |
    v
+---------------------------+
| Lambda Function           |
|  - Container image        |
|  - VPC private subnets    |
|  - KMS-encrypted env (SC-28)
|  - X-Ray tracing (SI-4)  |
|  - Reserved concurrency   |
+---------------------------+
    |
    +---> CloudWatch Logs (KMS-encrypted, AU-2/AU-3)
    +---> CloudWatch Alarms --> SNS (SI-4, IR-4)
    +---> DynamoDB Sessions (optional, KMS-encrypted)
```

## Usage

### Minimal Configuration

```hcl
module "mcp_server" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/mcp_server?ref=v1.0.0"

  name        = "my-tools"
  environment = "dev"
  image_uri   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mcp-server:latest"

  vpc_id                 = module.vpc.vpc_id
  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.vpc.lambda_security_group_id]

  kms_key_arn = module.kms.key_arn

  # Disable auth for local development
  enable_auth = false
}
```

### Production Configuration

```hcl
module "mcp_server" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/mcp_server?ref=v1.0.0"

  name        = "ai-tools"
  environment = "prod"
  image_uri   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mcp-server:v2.1.0"

  # Compute
  memory_size                    = 1024
  timeout                        = 300
  reserved_concurrent_executions = 50
  environment_variables = {
    LOG_LEVEL = "info"
    REGION    = "us-east-1"
  }

  # Networking
  vpc_id                 = module.vpc.vpc_id
  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.vpc.lambda_security_group_id]

  # Encryption
  kms_key_arn = module.kms.key_arn

  # Auth
  enable_auth = true

  # API
  throttle_rate_limit  = 200
  throttle_burst_limit = 100
  cors_allowed_origins = ["https://app.example.com"]
  waf_acl_arn          = module.waf.web_acl_arn

  # Sessions
  enable_session_table = true
  session_ttl_seconds  = 7200

  # ECR
  enable_ecr_repository   = true
  ecr_image_tag_mutability = "IMMUTABLE"
  ecr_scan_on_push        = true

  # Observability
  log_retention_days    = 365
  enable_xray_tracing   = true
  alarm_sns_topic_arn   = module.notifications.sns_topic_arn
  alarm_actions_enabled = true

  tags = {
    Team    = "platform"
    CostCenter = "ai-infra"
  }
}
```

## FedRAMP Controls

| Control   | Family                       | Implementation                                                     |
|-----------|------------------------------|--------------------------------------------------------------------|
| AC-6      | Access Control               | IAM least-privilege roles; no wildcard actions                     |
| AU-2/AU-3 | Audit and Accountability     | CloudWatch Logs with structured JSON access logs; KMS encryption   |
| CM-7      | Configuration Management     | Reserved concurrency limits; API throttling; least functionality   |
| IA-2/IA-8 | Identification & Auth        | Cognito JWT authorizer with OAuth 2.0 client credentials           |
| IR-4      | Incident Response            | SNS alarm notifications for automated incident alerting            |
| SC-7      | Boundary Protection          | VPC private subnets; WAF association; API Gateway as single entry  |
| SC-8      | Transmission Confidentiality | HTTPS-only API Gateway endpoints; TLS in transit                   |
| SC-12/13  | Cryptographic Key Management | KMS-managed keys for all encryption operations                     |
| SC-28     | Protection of Data at Rest   | KMS encryption for Lambda env vars, logs, DynamoDB, and ECR        |
| SI-4      | System Monitoring            | X-Ray tracing; 5 CloudWatch alarms; structured logging             |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name identifier for the MCP server resources | `string` | n/a | yes |
| `environment` | Deployment environment (dev, staging, or prod) | `string` | n/a | yes |
| `tags` | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| `image_uri` | ECR image URI for the Lambda function container image | `string` | n/a | yes |
| `memory_size` | Amount of memory in MB allocated to the Lambda function | `number` | `512` | no |
| `timeout` | Maximum execution time in seconds for the Lambda function | `number` | `180` | no |
| `reserved_concurrent_executions` | Reserved concurrent executions for the Lambda function (-1 for unreserved) | `number` | `-1` | no |
| `environment_variables` | Environment variables to pass to the Lambda function | `map(string)` | `{}` | no |
| `vpc_id` | ID of the VPC where the Lambda function will run | `string` | n/a | yes |
| `vpc_subnet_ids` | List of private subnet IDs for the Lambda function VPC configuration | `list(string)` | n/a | yes |
| `vpc_security_group_ids` | List of security group IDs for the Lambda function VPC configuration | `list(string)` | n/a | yes |
| `kms_key_arn` | ARN of the KMS key used to encrypt environment variables, logs, and data at rest | `string` | n/a | yes |
| `enable_auth` | Enable Cognito JWT authentication for the API Gateway (FedRAMP IA-2) | `bool` | `true` | no |
| `throttle_rate_limit` | API Gateway throttle rate limit (requests per second) | `number` | `100` | no |
| `throttle_burst_limit` | API Gateway throttle burst limit (maximum concurrent requests) | `number` | `50` | no |
| `cors_allowed_origins` | List of allowed CORS origins for the API Gateway | `list(string)` | `["*"]` | no |
| `waf_acl_arn` | ARN of the WAF v2 Web ACL to associate with the API Gateway stage | `string` | `null` | no |
| `enable_session_table` | Enable DynamoDB table for MCP session management | `bool` | `false` | no |
| `session_ttl_seconds` | TTL in seconds for session records in DynamoDB | `number` | `3600` | no |
| `enable_ecr_repository` | Enable creation of an ECR repository for the MCP server container image | `bool` | `false` | no |
| `ecr_image_tag_mutability` | Tag mutability setting for the ECR repository (IMMUTABLE recommended for production) | `string` | `"IMMUTABLE"` | no |
| `ecr_scan_on_push` | Enable image vulnerability scanning on push to ECR | `bool` | `true` | no |
| `log_retention_days` | Number of days to retain CloudWatch log events | `number` | `30` | no |
| `enable_xray_tracing` | Enable AWS X-Ray active tracing for the Lambda function (FedRAMP SI-4) | `bool` | `true` | no |
| `alarm_sns_topic_arn` | ARN of an existing SNS topic for CloudWatch alarm notifications (creates a new topic if null) | `string` | `null` | no |
| `alarm_actions_enabled` | Enable alarm actions for CloudWatch metric alarms | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `mcp_endpoint_url` | Full URL of the MCP JSON-RPC endpoint (POST/GET/DELETE /mcp) |
| `api_id` | ID of the API Gateway v2 HTTP API |
| `api_endpoint` | Base endpoint URL of the API Gateway v2 HTTP API |
| `lambda_function_arn` | ARN of the MCP server Lambda function |
| `lambda_function_name` | Name of the MCP server Lambda function |
| `lambda_role_arn` | ARN of the IAM role used by the Lambda function |
| `cognito_user_pool_id` | ID of the Cognito user pool (null if auth is disabled) |
| `cognito_user_pool_endpoint` | Endpoint of the Cognito user pool for JWT token issuance (null if auth is disabled) |
| `cognito_client_id` | Client ID of the Cognito user pool client (null if auth is disabled) |
| `ecr_repository_url` | URL of the ECR repository for the MCP server container image (null if ECR is disabled) |
| `session_table_name` | Name of the DynamoDB session table (null if sessions are disabled) |
| `log_group_name` | Name of the CloudWatch log group for the Lambda function |
| `api_log_group_name` | Name of the CloudWatch log group for the API Gateway access logs |
| `sns_topic_arn` | ARN of the SNS topic used for CloudWatch alarm notifications |

## Authentication

When `enable_auth = true`, the module creates a Cognito user pool with an OAuth 2.0 client credentials flow. To obtain an access token:

```bash
# Get the client secret from Cognito (or from your secrets manager)
CLIENT_ID=$(tofu output -raw cognito_client_id)
CLIENT_SECRET="<retrieve-from-cognito-console-or-secrets-manager>"
USER_POOL_DOMAIN=$(tofu output -raw cognito_user_pool_endpoint)

# Request an access token using client credentials grant
TOKEN=$(curl -s -X POST \
  "https://${USER_POOL_DOMAIN}/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&scope=mcp/invoke" \
  | jq -r '.access_token')

# Call the MCP endpoint
curl -X POST \
  "$(tofu output -raw mcp_endpoint_url)" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## MCP Client Configuration

Configure your MCP client to connect to the deployed server:

```json
{
  "mcpServers": {
    "my-tools": {
      "url": "https://<api-id>.execute-api.<region>.amazonaws.com/mcp",
      "headers": {
        "Authorization": "Bearer <access-token>"
      }
    }
  }
}
```

For clients that support OAuth 2.0 natively, configure the Cognito token endpoint directly.

## Design Decisions

- **Container images only**: The module uses `package_type = "Image"` for Lambda to support complex MCP server dependencies and runtimes beyond what ZIP packages offer. This aligns with the MCP specification's recommendation for server-side implementations.

- **VPC required**: Lambda always runs in VPC private subnets to satisfy FedRAMP SC-7 boundary protection requirements. This ensures the function has no direct internet access and all traffic routes through the VPC's network controls.

- **Cognito client credentials flow**: Machine-to-machine authentication via OAuth 2.0 client credentials is used instead of user pool sign-in because MCP clients are automated systems, not interactive users. This satisfies IA-2 and IA-8.

- **Three HTTP routes (POST, GET, DELETE)**: The MCP specification (2025-03-26) defines POST for JSON-RPC requests, GET for SSE-based streaming, and DELETE for session termination. All three routes share the same Lambda integration and authorization configuration.

- **KMS encryption everywhere**: A single KMS key encrypts Lambda environment variables, CloudWatch Logs, DynamoDB (if enabled), ECR (if enabled), and SNS topics. This centralizes key management per SC-12/SC-13.

- **Optional DynamoDB sessions**: Session state is opt-in via `enable_session_table` because not all MCP servers require stateful sessions. When enabled, the table uses PAY_PER_REQUEST billing to avoid capacity planning overhead and includes TTL for automatic cleanup.

- **SNS topic auto-creation**: The module creates an SNS topic for alarms if `alarm_sns_topic_arn` is not provided, allowing standalone deployments. In production, pass an existing topic to consolidate notifications.

- **Immutable ECR tags by default**: `ecr_image_tag_mutability = "IMMUTABLE"` prevents tag overwrites, ensuring deployed image references remain stable and auditable.

- **Structured JSON access logs**: API Gateway access logs use JSON format for easy integration with log analytics tools (CloudWatch Insights, OpenSearch, Splunk) and to satisfy AU-3 content requirements.

- **Alarm thresholds tied to timeout**: The Lambda duration and API Gateway latency alarms use dynamic thresholds (80% and 90% of the configured timeout) so they automatically adjust when timeout values change.
