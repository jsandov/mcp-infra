# ALB Module

Creates an Application Load Balancer with HTTP and optional HTTPS listeners, a default target group, configurable health checks, and optional WAF integration.

## Usage

### HTTP Only

```hcl
module "alb" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/alb?ref=v1.0.0"

  environment        = "dev"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.web_security_group_id]
  target_port        = 8080

  tags = {
    Project = "my-project"
  }
}
```

### With HTTPS and WAF

```hcl
module "alb" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/alb?ref=v1.0.0"

  environment        = "prod"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.web_security_group_id]
  target_port        = 8080
  certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
  waf_acl_arn        = aws_wafv2_web_acl.main.arn

  enable_deletion_protection = true

  health_check_path    = "/health"
  health_check_matcher = "200-299"

  tags = {
    Project = "my-project"
  }
}
```

When a `certificate_arn` is provided, the HTTP listener automatically redirects to HTTPS (301).

## Inputs

| Name                              | Type           | Default                                  | Required | Description                                 |
| --------------------------------- | -------------- | ---------------------------------------- | -------- | ------------------------------------------- |
| `name`                            | `string`       | `alb`                                    | no       | Name for the ALB (prefixed with environment)|
| `environment`                     | `string`       | —                                        | yes      | Environment name (dev, staging, prod)       |
| `vpc_id`                          | `string`       | —                                        | yes      | VPC ID for the target group                 |
| `subnet_ids`                      | `list(string)` | —                                        | yes      | Subnets for the ALB (min 2 AZs)            |
| `security_group_ids`              | `list(string)` | —                                        | yes      | Security groups for the ALB                 |
| `internal`                        | `bool`         | `false`                                  | no       | Internal or internet-facing                 |
| `enable_deletion_protection`      | `bool`         | `false`                                  | no       | Prevent accidental ALB deletion             |
| `idle_timeout`                    | `number`       | `60`                                     | no       | Idle connection timeout in seconds (1-4000) |
| `target_port`                     | `number`       | `80`                                     | no       | Port targets listen on                      |
| `target_type`                     | `string`       | `ip`                                     | no       | Target type (instance, ip, lambda, alb)     |
| `deregistration_delay`            | `number`       | `30`                                     | no       | Seconds before deregistering targets (0-3600)|
| `certificate_arn`                 | `string`       | `null`                                   | no       | ACM certificate ARN for HTTPS               |
| `ssl_policy`                      | `string`       | `ELBSecurityPolicy-TLS13-1-2-2021-06`   | no       | TLS policy for HTTPS listener               |
| `waf_acl_arn`                     | `string`       | `null`                                   | no       | WAFv2 ACL ARN for Layer 7 protection        |
| `health_check_path`               | `string`       | `/`                                      | no       | Health check request path                   |
| `health_check_matcher`            | `string`       | `200`                                    | no       | Expected HTTP status codes                  |
| `health_check_interval`           | `number`       | `30`                                     | no       | Seconds between health checks               |
| `health_check_timeout`            | `number`       | `5`                                      | no       | Health check timeout in seconds             |
| `health_check_healthy_threshold`  | `number`       | `3`                                      | no       | Checks before marking healthy               |
| `health_check_unhealthy_threshold`| `number`       | `3`                                      | no       | Checks before marking unhealthy             |
| `access_logs_bucket`              | `string`       | `null`                                   | no       | S3 bucket for access logs (null = disabled) |
| `access_logs_prefix`              | `string`       | `alb-logs`                               | no       | S3 key prefix for access logs               |
| `tags`                            | `map(string)`  | `{}`                                     | no       | Additional tags for all resources            |

## Outputs

| Name                       | Description                                       |
| -------------------------- | ------------------------------------------------- |
| `alb_id`                   | The ID of the ALB                                 |
| `alb_arn`                  | The ARN of the ALB                                |
| `alb_dns_name`             | The DNS name of the ALB                           |
| `alb_zone_id`              | Hosted zone ID for Route 53 alias records         |
| `default_target_group_arn` | ARN of the default target group                   |
| `http_listener_arn`        | ARN of the HTTP listener                          |
| `https_listener_arn`       | ARN of the HTTPS listener (null if no cert)       |
| `waf_acl_association_id`   | ID of the WAF association (null if no WAF)        |

## Security Features

- **TLS 1.3 by default**: Uses `ELBSecurityPolicy-TLS13-1-2-2021-06` which requires TLS 1.2+
- **HTTP to HTTPS redirect**: Automatic when a certificate is provided
- **Drop invalid headers**: `drop_invalid_header_fields` enabled to prevent HTTP request smuggling
- **WAF integration**: Optional WAFv2 association for OWASP Top 10 protection
- **Connection draining**: Configurable deregistration delay for graceful shutdown
- **Deletion protection**: Off by default for dev, enable for production
- **Target type `ip`**: Default supports Fargate and container-based deployments
