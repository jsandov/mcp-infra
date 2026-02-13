# API Gateway Module

Creates a production-hardened AWS API Gateway v2 (HTTP API) with access logging, throttling, optional CORS, VPC Link, WAF integration, and KMS-encrypted logs.

Aligned with **AWS Well-Architected Framework** Security Pillar and **FedRAMP** compliance controls.

## Usage

### Basic HTTP API

```hcl
module "api_gateway" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/api_gateway?ref=v1.0.0"

  name        = "my-api"
  environment = "dev"

  tags = {
    Project = "my-project"
  }
}
```

### Production API with WAF, CORS, and KMS Encryption

```hcl
module "api_gateway" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/api_gateway?ref=v1.0.0"

  name        = "my-api"
  description = "Production API for my-service"
  environment = "prod"

  # Throttling
  throttling_rate_limit  = 2000
  throttling_burst_limit = 1000

  # Logging with KMS encryption
  log_retention_days = 365
  kms_key_arn        = module.kms.key_arn

  # CORS
  enable_cors          = true
  cors_allowed_origins = ["https://app.example.com"]
  cors_allowed_methods = ["GET", "POST", "PUT", "DELETE"]

  # WAF
  waf_acl_arn = aws_wafv2_web_acl.api.arn

  tags = {
    Project = "my-project"
  }
}
```

### With VPC Link for Private Backends

```hcl
module "api_gateway" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/api_gateway?ref=v1.0.0"

  name        = "internal-api"
  environment = "prod"

  vpc_link_subnet_ids         = module.vpc.private_subnet_ids
  vpc_link_security_group_ids = [module.security_groups.app_security_group_id]

  tags = {
    Project = "my-project"
  }
}
```

### Shared Gateway for Multiple Services

Use the `api_gateway` module as shared infrastructure and the [`api_gateway_routes`](../api_gateway_routes/) module for per-service route isolation. Each team manages their own routes in a separate state file.

```hcl
# Platform team: shared gateway (platform.tfstate)
module "shared_api" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/api_gateway?ref=v2.0.0"

  name        = "platform-api"
  environment = "prod"

  enable_jwt_authorizer = true
  jwt_issuer            = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_AbCdEfGhI"
  jwt_audience          = ["1a2b3c4d5e6f7g8h9i0j"]

  kms_key_arn    = module.kms.key_arn
  waf_acl_arn    = aws_wafv2_web_acl.api.arn

  route_throttle_overrides = {
    "POST /mcp"             = { throttling_rate_limit = 100, throttling_burst_limit = 50 }
    "POST /billing/invoices" = { throttling_rate_limit = 200, throttling_burst_limit = 100 }
  }
}

# Team Alpha: MCP routes (mcp.tfstate)
module "mcp_routes" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/api_gateway_routes?ref=v1.0.0"

  api_id            = module.shared_api.api_id
  api_execution_arn = module.shared_api.execution_arn
  service_name      = "mcp-server"

  lambda_function_name = module.mcp_lambda.function_name
  lambda_invoke_arn    = module.mcp_lambda.invoke_arn

  routes = {
    "POST /mcp"   = { authorization_type = "JWT", authorizer_id = module.shared_api.authorizer_id }
    "GET /mcp"    = { authorization_type = "JWT", authorizer_id = module.shared_api.authorizer_id }
    "DELETE /mcp" = { authorization_type = "JWT", authorizer_id = module.shared_api.authorizer_id }
  }
}

# Team Beta: Billing routes (billing.tfstate)
module "billing_routes" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/api_gateway_routes?ref=v1.0.0"

  api_id            = data.terraform_remote_state.platform.outputs.api_id
  api_execution_arn = data.terraform_remote_state.platform.outputs.execution_arn
  service_name      = "billing"

  lambda_function_name = aws_lambda_function.billing.function_name
  lambda_invoke_arn    = aws_lambda_function.billing.invoke_arn

  routes = {
    "POST /billing/invoices" = { authorization_type = "JWT", authorizer_id = data.terraform_remote_state.platform.outputs.authorizer_id }
    "GET /billing/invoices"  = { authorization_type = "JWT", authorizer_id = data.terraform_remote_state.platform.outputs.authorizer_id }
  }
}
```

The API and stage have `lifecycle { prevent_destroy = true }` — neither team can accidentally delete the shared gateway.

## Inputs

| Name                            | Type           | Default                                              | Required | Description                                    |
| ------------------------------- | -------------- | ---------------------------------------------------- | -------- | ---------------------------------------------- |
| `name`                          | `string`       | `api`                                                | no       | API name (prefixed with environment)           |
| `description`                   | `string`       | `""`                                                 | no       | API description                                |
| `environment`                   | `string`       | ---                                                    | yes      | Environment name (dev, staging, prod)          |
| `enable_auto_deploy`            | `bool`         | `true`                                               | no       | Auto-deploy changes to default stage           |
| `throttling_rate_limit`         | `number`       | `1000`                                               | no       | Requests/second rate limit (1--10000)           |
| `throttling_burst_limit`        | `number`       | `500`                                                | no       | Burst capacity (1--5000)                        |
| `enable_access_logging`         | `bool`         | `true`                                               | no       | Enable CloudWatch access logging               |
| `log_retention_days`            | `number`       | `90`                                                 | no       | Log retention in days                          |
| `kms_key_arn`                   | `string`       | `null`                                               | no       | KMS key for log encryption (null = AWS default)|
| `enable_cors`                   | `bool`         | `false`                                              | no       | Enable CORS                                    |
| `cors_allowed_origins`          | `list(string)` | `[]`                                                 | no       | Allowed CORS origins                           |
| `cors_allowed_methods`          | `list(string)` | `["GET","POST","PUT","DELETE","OPTIONS"]`            | no       | Allowed CORS methods                           |
| `cors_allowed_headers`          | `list(string)` | `["Content-Type","Authorization","X-Amz-Date",...] ` | no       | Allowed CORS headers                           |
| `cors_expose_headers`           | `list(string)` | `[]`                                                 | no       | CORS exposed headers                           |
| `cors_max_age`                  | `number`       | `86400`                                              | no       | CORS preflight cache (seconds)                 |
| `cors_allow_credentials`        | `bool`         | `false`                                              | no       | Allow credentials in CORS                      |
| `vpc_link_subnet_ids`           | `list(string)` | `[]`                                                 | no       | Subnet IDs for VPC Link (empty = no link)      |
| `vpc_link_security_group_ids`   | `list(string)` | `[]`                                                 | no       | Security groups for VPC Link                   |
| `waf_acl_arn`                   | `string`       | `null`                                               | no       | WAFv2 ACL ARN (null = no WAF)                  |
| `enable_jwt_authorizer`         | `bool`         | `false`                                              | no       | Create a shared JWT authorizer on the API      |
| `jwt_issuer`                    | `string`       | `null`                                               | no       | JWT issuer URL (required if authorizer enabled)|
| `jwt_audience`                  | `list(string)` | `[]`                                                 | no       | JWT audience values (required if authorizer)   |
| `route_throttle_overrides`      | `map(object)`  | `{}`                                                 | no       | Per-route throttle overrides (rate + burst)    |
| `tags`                          | `map(string)`  | `{}`                                                 | no       | Additional tags                                |

## Outputs

| Name                        | Description                                              |
| --------------------------- | -------------------------------------------------------- |
| `api_id`                    | The ID of the API Gateway                                |
| `api_arn`                   | The ARN of the API Gateway                               |
| `api_endpoint`              | The default endpoint URL                                 |
| `stage_id`                  | The ID of the default stage                              |
| `stage_invoke_url`          | The invocation URL of the default stage                  |
| `cloudwatch_log_group_name` | Log group name (null if logging disabled)                |
| `cloudwatch_log_group_arn`  | Log group ARN (null if logging disabled)                 |
| `vpc_link_id`               | VPC Link ID (null if no VPC Link)                        |
| `execution_arn`             | Execution ARN (for Lambda permissions in route modules)  |
| `authorizer_id`             | Shared JWT authorizer ID (null if not configured)        |

## Security Features

- **Access logging**: CloudWatch Logs enabled by default with 90-day retention
- **Log encryption**: Optional customer-managed KMS key (FedRAMP AU-9, SC-28)
- **Throttling**: Configurable rate and burst limits to prevent abuse (SEC-06)
- **Least-privilege logging**: CloudWatch access logging scoped to specific log group
- **WAF integration**: Optional WAFv2 association for OWASP Top 10 protection (SC-7)
- **VPC Link**: Optional private backend connectivity (SC-7)
- **CORS**: Restrictive by default, configurable origins and methods
- **Auto-deploy**: Changes deploy automatically to reduce manual intervention risk

## FedRAMP Controls

| Control | Requirement                          | Implementation                              |
| ------- | ------------------------------------ | ------------------------------------------- |
| AU-2    | Audit events                         | CloudWatch access logs enabled by default   |
| AU-3    | Content of audit records             | Request/response metadata in access logs    |
| AU-9    | Protection of audit information      | KMS encryption on log group                 |
| SC-7    | Boundary protection                  | VPC Link + WAF integration                  |
| SC-8    | Transmission confidentiality         | HTTPS-only API endpoint (API Gateway v2)    |
| SC-28   | Protection of information at rest    | KMS encryption for log data                 |
| SI-4    | System monitoring                    | Access logging + throttling metrics         |
