# CloudWatch Alarms Module

Provides configurable CloudWatch metric alarms for FedRAMP SI-4 continuous monitoring. Supports ALB, API Gateway, and VPC Flow Logs metrics with SNS notifications and optional auto-remediation via Lambda.

## Usage

### Basic ALB Monitoring

```hcl
module "alarms" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/cloudwatch_alarms?ref=v1.0.0"

  name        = "my-app"
  environment = "prod"

  # ALB alarms
  enable_alb_5xx_alarm    = true
  enable_alb_unhealthy_alarm = true
  alb_arn_suffix             = module.alb.arn_suffix
  alb_target_group_arn_suffix = module.alb.target_group_arn_suffix

  tags = {
    Project = "my-project"
  }
}
```

### Full Stack Monitoring

```hcl
module "alarms" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/cloudwatch_alarms?ref=v1.0.0"

  name        = "my-app"
  environment = "prod"
  kms_key_arn = module.kms.key_arn

  # ALB alarms
  enable_alb_5xx_alarm           = true
  enable_alb_unhealthy_alarm     = true
  alb_arn_suffix                 = module.alb.arn_suffix
  alb_target_group_arn_suffix    = module.alb.target_group_arn_suffix

  # API Gateway alarms
  enable_apigw_5xx_alarm     = true
  enable_apigw_4xx_alarm     = true
  enable_apigw_latency_alarm = true
  apigw_api_id               = module.apigw.api_id

  # VPC Flow Logs alarm
  enable_vpc_rejected_alarm   = true
  vpc_flow_log_group_name     = module.vpc.flow_log_group_name

  # Auto-remediation
  remediation_lambda_arn = module.remediation.lambda_arn

  tags = {
    Project = "my-project"
  }
}
```

## Inputs

| Name | Type | Default | Required | Description |
| ---- | ---- | ------- | -------- | ----------- |
| `name` | `string` | `"infra"` | no | Name prefix for alarm resources |
| `environment` | `string` | -- | yes | Environment name (dev, staging, prod) |
| `kms_key_arn` | `string` | `null` | no | KMS key ARN for SNS topic encryption |
| `remediation_lambda_arn` | `string` | `""` | no | Lambda ARN for auto-remediation actions |
| `tags` | `map(string)` | `{}` | no | Additional tags for all resources |
| `alb_arn_suffix` | `string` | `""` | no | ALB ARN suffix (required when ALB alarms enabled) |
| `alb_target_group_arn_suffix` | `string` | `""` | no | ALB target group ARN suffix (required when unhealthy alarm enabled) |
| `enable_alb_5xx_alarm` | `bool` | `false` | no | Enable ALB 5xx error alarm |
| `alb_5xx_threshold` | `number` | `50` | no | ALB 5xx error count threshold |
| `alb_5xx_period` | `number` | `300` | no | ALB 5xx evaluation period (seconds) |
| `alb_5xx_evaluation_periods` | `number` | `3` | no | ALB 5xx number of evaluation periods |
| `enable_alb_unhealthy_alarm` | `bool` | `false` | no | Enable ALB unhealthy targets alarm |
| `alb_unhealthy_threshold` | `number` | `0` | no | ALB unhealthy target count threshold |
| `alb_unhealthy_period` | `number` | `300` | no | ALB unhealthy evaluation period (seconds) |
| `alb_unhealthy_evaluation_periods` | `number` | `3` | no | ALB unhealthy number of evaluation periods |
| `apigw_api_id` | `string` | `""` | no | API Gateway API ID (required when API GW alarms enabled) |
| `enable_apigw_5xx_alarm` | `bool` | `false` | no | Enable API Gateway 5xx error alarm |
| `apigw_5xx_threshold` | `number` | `50` | no | API Gateway 5xx error count threshold |
| `apigw_5xx_period` | `number` | `300` | no | API Gateway 5xx evaluation period (seconds) |
| `apigw_5xx_evaluation_periods` | `number` | `3` | no | API Gateway 5xx number of evaluation periods |
| `enable_apigw_4xx_alarm` | `bool` | `false` | no | Enable API Gateway 4xx error alarm |
| `apigw_4xx_threshold` | `number` | `200` | no | API Gateway 4xx error count threshold |
| `apigw_4xx_period` | `number` | `300` | no | API Gateway 4xx evaluation period (seconds) |
| `apigw_4xx_evaluation_periods` | `number` | `3` | no | API Gateway 4xx number of evaluation periods |
| `enable_apigw_latency_alarm` | `bool` | `false` | no | Enable API Gateway latency alarm |
| `apigw_latency_threshold` | `number` | `5000` | no | API Gateway p99 latency threshold (ms) |
| `apigw_latency_period` | `number` | `300` | no | API Gateway latency evaluation period (seconds) |
| `apigw_latency_evaluation_periods` | `number` | `3` | no | API Gateway latency number of evaluation periods |
| `vpc_flow_log_group_name` | `string` | `""` | no | CloudWatch Log Group name for VPC Flow Logs |
| `enable_vpc_rejected_alarm` | `bool` | `false` | no | Enable VPC rejected packets alarm |
| `vpc_rejected_threshold` | `number` | `1000` | no | VPC rejected packet count threshold |
| `vpc_rejected_period` | `number` | `300` | no | VPC rejected packets evaluation period (seconds) |
| `vpc_rejected_evaluation_periods` | `number` | `3` | no | VPC rejected packets number of evaluation periods |

## Outputs

| Name | Description |
| ---- | ----------- |
| `sns_topic_arn` | The ARN of the SNS alarm notification topic |
| `sns_topic_name` | The name of the SNS alarm notification topic |
| `alb_5xx_alarm_arn` | The ARN of the ALB 5xx error alarm (null if disabled) |
| `alb_unhealthy_alarm_arn` | The ARN of the ALB unhealthy targets alarm (null if disabled) |
| `apigw_5xx_alarm_arn` | The ARN of the API Gateway 5xx alarm (null if disabled) |
| `apigw_4xx_alarm_arn` | The ARN of the API Gateway 4xx alarm (null if disabled) |
| `apigw_latency_alarm_arn` | The ARN of the API Gateway latency alarm (null if disabled) |
| `vpc_rejected_alarm_arn` | The ARN of the VPC rejected packets alarm (null if disabled) |

## FedRAMP Controls

| Control | Title | How This Module Helps |
| ------- | ----- | --------------------- |
| SI-4 | System Monitoring | Provides continuous metric monitoring with configurable thresholds for ALB, API Gateway, and VPC traffic |
| SI-5 | Security Alerts, Advisories, and Directives | SNS topic delivers real-time alarm notifications to subscribed operators |
| IR-4 | Incident Handling | Optional auto-remediation Lambda integration enables automated incident response |
| AU-6 | Audit Record Review, Analysis, and Reporting | VPC Flow Logs rejected packets alarm supports audit log anomaly detection |
