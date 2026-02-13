# MCP Tenant Metering Module

Application-layer metering for multi-tenant MCP (Model Context Protocol) deployments.

## Description

AWS API Gateway v2 (HTTP API) does not support usage plans or API keys for
rate-limiting individual tenants, unlike REST API (v1). This module fills that
gap by implementing application-layer metering using:

- **DynamoDB** for per-tenant usage tracking (request counts, error counts,
  timestamps) written by the MCP server Lambda at runtime.
- **CloudWatch Log Metric Filters** for aggregate request and error counting
  from API Gateway access logs.
- **CloudWatch Alarms** for quota enforcement and anomaly detection.
- **SNS Notifications** for alerting on threshold breaches.

This approach satisfies FedRAMP audit and monitoring requirements while
providing the flexibility needed for multi-tenant SaaS deployments.

## Architecture

```text
API Gateway Access Logs --> CloudWatch Log Group
                                |
                                | Log Metric Filter (count requests)
                                v
                       CloudWatch Custom Metrics
                       (namespace: MCP/TenantMetering)
                                |
                                v
                       CloudWatch Alarms (quota exceeded)
                                |
                                v
                       SNS Topic --> Notifications

MCP Server Lambda --> DynamoDB Usage Table
                      (tenant_id + period as composite key)
                      Attributes: request_count, error_count, last_request_time
```

**Two data paths:**

1. **Aggregate metrics** (top path): API Gateway access logs are processed by
   CloudWatch metric filters to count total requests and errors. These feed
   into CloudWatch alarms for platform-wide monitoring.

2. **Per-tenant tracking** (bottom path): The MCP server Lambda writes usage
   records to DynamoDB on every request, keyed by `tenant_id` and time period.
   This enables per-tenant quota enforcement, billing, and reporting.

## Usage

### Minimal Configuration

```hcl
module "mcp_metering" {
  source = "git::https://github.com/<org>/cloud-voyager-infra.git//infra/modules/mcp_tenant_metering?ref=v1.0.0"

  name             = "myapp"
  environment      = "dev"
  kms_key_arn      = module.kms.key_arn
  lambda_role_name = module.mcp_server.lambda_role_name
}
```

### Production with API Gateway Logs and External SNS Topic

```hcl
module "mcp_metering" {
  source = "git::https://github.com/<org>/cloud-voyager-infra.git//infra/modules/mcp_tenant_metering?ref=v1.0.0"

  name                          = "myapp"
  environment                   = "prod"
  kms_key_arn                   = module.kms.key_arn
  lambda_role_name              = module.mcp_server.lambda_role_name
  api_log_group_name            = module.mcp_server.api_log_group_name
  alarm_sns_topic_arn           = module.notifications.sns_topic_arn
  enable_quota_alarm            = true
  quota_request_threshold       = 50000
  quota_alarm_period            = 3600
  quota_alarm_evaluation_periods = 2
  error_rate_threshold          = 100
  usage_ttl_days                = 365

  tags = {
    Project = "mcp-platform"
    Team    = "platform-eng"
  }
}
```

## Integration with mcp_server Module

This module is designed to work alongside the `mcp_server` module. Wire them
together by passing outputs between modules:

```hcl
module "mcp_server" {
  source = "git::https://github.com/<org>/cloud-voyager-infra.git//infra/modules/mcp_server?ref=v1.0.0"
  # ... server configuration ...
}

module "mcp_metering" {
  source = "git::https://github.com/<org>/cloud-voyager-infra.git//infra/modules/mcp_tenant_metering?ref=v1.0.0"

  name               = "myapp"
  environment        = "prod"
  kms_key_arn        = module.kms.key_arn
  lambda_role_name   = module.mcp_server.lambda_role_name
  api_log_group_name = module.mcp_server.api_log_group_name
}
```

The MCP server Lambda needs the usage table name as an environment variable.
Add it to your Lambda configuration:

```hcl
environment {
  variables = {
    USAGE_TABLE_NAME    = module.mcp_metering.usage_table_name
    METRIC_NAMESPACE    = module.mcp_metering.metric_namespace
  }
}
```

## Per-Tenant Custom Metrics

The CloudWatch metric filters provide aggregate (platform-wide) metrics. For
per-tenant monitoring and quota enforcement, the MCP server application code
should publish custom CloudWatch metrics with a `TenantId` dimension.

Example (Python Lambda):

```python
import boto3
import os

cloudwatch = boto3.client("cloudwatch")

def publish_tenant_metric(tenant_id: str, metric_name: str, value: float):
    """Publish a per-tenant metric to CloudWatch."""
    cloudwatch.put_metric_data(
        Namespace=os.environ["METRIC_NAMESPACE"],
        MetricData=[
            {
                "MetricName": metric_name,
                "Dimensions": [
                    {"Name": "TenantId", "Value": tenant_id},
                ],
                "Value": value,
                "Unit": "Count",
            }
        ],
    )

# In the request handler:
publish_tenant_metric(tenant_id, "RequestCount", 1)
```

You can then create per-tenant CloudWatch alarms using these dimensions, or
use CloudWatch Metrics Insights for cross-tenant analysis.

## FedRAMP Controls

| Control | Description                      | Implementation                                            |
| ------- | -------------------------------- | --------------------------------------------------------- |
| AU-2    | Audit events                     | DynamoDB usage table records all API requests per tenant   |
| AU-3    | Content of audit records         | Records include tenant_id, period, request/error counts   |
| SI-4    | Information system monitoring    | CloudWatch metric filters and error rate alarms           |
| CM-7    | Least functionality / quotas     | Request rate alarms enforce usage thresholds              |
| IR-4    | Incident handling                | SNS notifications for threshold breaches                  |

## Inputs

| Name                           | Type        | Default              | Required | Description                                                                 |
| ------------------------------ | ----------- | -------------------- | -------- | --------------------------------------------------------------------------- |
| `name`                         | `string`    | n/a                  | yes      | Name identifier for metering resources (1-40 lowercase chars/hyphens)       |
| `environment`                  | `string`    | n/a                  | yes      | Deployment environment: `dev`, `staging`, or `prod`                         |
| `tags`                         | `map(string)` | `{}`               | no       | Additional tags merged with defaults (Name, Environment, ManagedBy)         |
| `kms_key_arn`                  | `string`    | n/a                  | yes      | KMS key ARN for encrypting DynamoDB, SNS, and CloudWatch                    |
| `lambda_role_name`             | `string`    | n/a                  | yes      | MCP server Lambda execution role name (for DynamoDB access policy)          |
| `api_log_group_name`           | `string`    | `null`               | no       | CloudWatch log group for API GW access logs (enables metric filters)        |
| `metric_namespace`             | `string`    | `MCP/TenantMetering` | no       | CloudWatch custom metric namespace                                          |
| `usage_ttl_days`               | `number`    | `90`                 | no       | Days to retain DynamoDB usage records (min: 1)                              |
| `enable_quota_alarm`           | `bool`      | `true`               | no       | Enable request quota and error rate alarms                                  |
| `quota_request_threshold`      | `number`    | `10000`              | no       | Request count threshold per alarm period (min: 1)                           |
| `quota_alarm_period`           | `number`    | `86400`              | no       | Alarm evaluation period in seconds (valid CW periods only)                  |
| `quota_alarm_evaluation_periods` | `number`  | `1`                  | no       | Consecutive breach periods before alarm triggers (min: 1)                   |
| `error_rate_threshold`         | `number`    | `50`                 | no       | 5xx error count threshold per 5-minute period (min: 1)                      |
| `alarm_sns_topic_arn`          | `string`    | `null`               | no       | External SNS topic ARN for alerts (creates new topic if null)               |

## Outputs

| Name                              | Description                                                                 |
| --------------------------------- | --------------------------------------------------------------------------- |
| `usage_table_name`                | Name of the DynamoDB usage tracking table                                   |
| `usage_table_arn`                 | ARN of the DynamoDB usage tracking table                                    |
| `metric_namespace`                | CloudWatch custom metric namespace for tenant metering                      |
| `sns_topic_arn`                   | ARN of the SNS topic for metering alerts                                    |
| `request_count_metric_filter_name` | Name of the request count metric filter (null if no log group)             |
| `error_count_metric_filter_name`  | Name of the error count metric filter (null if no log group)               |

## Design Decisions

### Why DynamoDB for Usage Tracking?

DynamoDB provides single-digit-millisecond reads and writes at any scale, which
is critical for recording usage on every API request without adding latency.
The PAY_PER_REQUEST billing mode ensures cost scales linearly with actual usage
rather than provisioned capacity. The composite key (`tenant_id` + `period`)
enables efficient queries for both per-tenant history and cross-tenant
reporting via the GSI.

### Why CloudWatch Metric Filters for Aggregate Metrics?

Metric filters operate on API Gateway access logs that are already being
written, so they add no overhead to the request path. They provide real-time
aggregate metrics (total requests, total errors) that feed directly into
CloudWatch alarms. This is more efficient than querying DynamoDB for aggregate
counts and avoids read capacity consumption.

### Why Application-Layer Metering for Per-Tenant Tracking?

API Gateway v2 (HTTP API) does not support usage plans or API keys, which are
the primary mechanisms for per-client metering in REST API (v1). Rather than
downgrading to REST API (losing HTTP/2, lower latency, and lower cost),
this module implements metering at the application layer. The MCP server
Lambda extracts the tenant identity from the JWT token (set by the Cognito
authorizer) and writes usage records to DynamoDB. This approach provides more
flexibility than API Gateway usage plans, including custom quota periods,
graceful degradation, and tenant-specific rate limits.
