# Lambda Module

Creates a FedRAMP-compliant AWS Lambda function with KMS-encrypted environment variables and CloudWatch logs, least-privilege IAM execution role, optional VPC deployment for network isolation, X-Ray distributed tracing, dead-letter queue support, and an optional function URL for direct HTTPS invocation.

## Usage

### Zip Deployment

```hcl
module "lambda" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/lambda?ref=v2.0.0"

  function_name = "my-api-handler"
  description   = "Handles API requests for the application"
  runtime       = "python3.12"
  handler       = "index.handler"
  filename      = "${path.module}/builds/handler.zip"
  environment   = "prod"

  kms_key_arn     = module.kms.key_arn
  log_kms_key_arn = module.kms.key_arn

  environment_variables = {
    LOG_LEVEL = "INFO"
    TABLE_NAME = module.dynamodb.table_name
  }

  tags = {
    Project = "my-project"
  }
}
```

### S3 Deployment

```hcl
module "lambda" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/lambda?ref=v2.0.0"

  function_name = "data-processor"
  description   = "Processes data from S3 events"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  s3_bucket     = "my-deployment-bucket"
  s3_key        = "lambdas/data-processor/v1.0.0.zip"
  environment   = "staging"
  memory_size   = 512
  timeout       = 120

  dead_letter_target_arn = aws_sqs_queue.dlq.arn

  tags = {
    Project = "data-pipeline"
  }
}
```

## VPC Deployment

Deploy the Lambda function inside a VPC for private resource access and network isolation. When `vpc_subnet_ids` is provided, the module automatically attaches the `AWSLambdaVPCAccessExecutionRole` managed policy.

```hcl
module "lambda" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/lambda?ref=v2.0.0"

  function_name = "private-api-handler"
  description   = "Handles requests with access to private VPC resources"
  runtime       = "python3.12"
  handler       = "app.handler"
  filename      = "${path.module}/builds/handler.zip"
  environment   = "prod"

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.security_groups.lambda_security_group_id]

  kms_key_arn     = module.kms.key_arn
  log_kms_key_arn = module.kms.key_arn

  environment_variables = {
    DB_HOST = module.rds.endpoint
  }

  tags = {
    Project = "my-project"
  }
}
```

## Container Deployment

Deploy from an ECR container image. When `image_uri` is provided, the `runtime` and `handler` arguments are ignored and `package_type` is automatically set to `Image`.

```hcl
module "lambda" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/lambda?ref=v2.0.0"

  function_name = "ml-inference"
  description   = "Runs ML inference from a container image"
  runtime       = "provided.al2023"
  image_uri     = "{AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ml-inference:latest"
  environment   = "prod"
  memory_size   = 4096
  timeout       = 300

  kms_key_arn     = module.kms.key_arn
  log_kms_key_arn = module.kms.key_arn

  tags = {
    Project = "ml-platform"
  }
}
```

## FedRAMP Controls

| Control | ID    | Implementation                                                                 |
| ------- | ----- | ------------------------------------------------------------------------------ |
| SC-8    | SC-8  | Function URL uses HTTPS; data in transit encrypted via TLS                     |
| SC-28   | SC-28 | Environment variables encrypted with KMS; CloudWatch logs encrypted with KMS   |
| AC-6    | AC-6  | Least-privilege IAM execution role; only required managed policies attached    |
| AU-2    | AU-2  | CloudWatch log group with configurable retention; basic execution role grants log access |
| SI-4    | SI-4  | X-Ray active tracing enabled by default for distributed monitoring             |
| SC-7    | SC-7  | Optional VPC deployment for network boundary protection and isolation          |

## Inputs

| Name                           | Type           | Default        | Required | Description                                                              |
| ------------------------------ | -------------- | -------------- | -------- | ------------------------------------------------------------------------ |
| `function_name`                | `string`       | --             | yes      | Unique name for the Lambda function (1-64 chars, alphanumeric/-/_)       |
| `description`                  | `string`       | `""`           | no       | Description of the Lambda function                                       |
| `runtime`                      | `string`       | --             | yes      | Lambda runtime identifier (e.g., python3.12, nodejs20.x)                 |
| `handler`                      | `string`       | `null`         | no       | Function entrypoint (required for zip, not for container)                |
| `timeout`                      | `number`       | `30`           | no       | Maximum execution time in seconds (1-900)                                |
| `memory_size`                  | `number`       | `128`          | no       | Memory in MB available at runtime (128-10240)                            |
| `filename`                     | `string`       | `null`         | no       | Path to local zip file containing function code                          |
| `s3_bucket`                    | `string`       | `null`         | no       | S3 bucket containing the deployment package                              |
| `s3_key`                       | `string`       | `null`         | no       | S3 object key of the deployment package                                  |
| `image_uri`                    | `string`       | `null`         | no       | ECR container image URI for container deployments                        |
| `environment_variables`        | `map(string)`  | `{}`           | no       | Map of environment variables for the function                            |
| `kms_key_arn`                  | `string`       | `null`         | no       | KMS key ARN to encrypt environment variables at rest                     |
| `vpc_subnet_ids`               | `list(string)` | `[]`           | no       | Subnet IDs for VPC-connected Lambda execution                           |
| `vpc_security_group_ids`       | `list(string)` | `[]`           | no       | Security group IDs for VPC-connected Lambda execution                    |
| `enable_xray_tracing`          | `bool`         | `true`         | no       | Enable AWS X-Ray active tracing                                          |
| `reserved_concurrent_executions` | `number`     | `-1`           | no       | Reserved concurrent executions (-1 for unreserved)                       |
| `dead_letter_target_arn`       | `string`       | `null`         | no       | ARN of SNS topic or SQS queue for failed invocation dead-letter delivery |
| `log_retention_days`           | `number`       | `30`           | no       | CloudWatch log retention in days (valid CW values only)                  |
| `log_kms_key_arn`              | `string`       | `null`         | no       | KMS key ARN to encrypt CloudWatch log data at rest                       |
| `enable_function_url`          | `bool`         | `false`        | no       | Enable a Lambda function URL for direct HTTPS invocation                 |
| `function_url_auth_type`       | `string`       | `"AWS_IAM"`    | no       | Authorization type for the function URL (AWS_IAM or NONE)                |
| `environment`                  | `string`       | --             | yes      | Environment name (dev, staging, prod)                                    |
| `tags`                         | `map(string)`  | `{}`           | no       | Additional tags to apply to all resources                                |

## Outputs

| Name             | Description                                                    |
| ---------------- | -------------------------------------------------------------- |
| `function_arn`   | The ARN of the Lambda function                                 |
| `function_name`  | The name of the Lambda function                                |
| `invoke_arn`     | The invocation ARN for API Gateway integration                 |
| `qualified_arn`  | The ARN of the Lambda function with version qualifier          |
| `role_arn`       | The ARN of the IAM execution role                              |
| `role_name`      | The name of the IAM execution role                             |
| `log_group_name` | The name of the CloudWatch log group                           |
| `log_group_arn`  | The ARN of the CloudWatch log group                            |
| `function_url`   | The Lambda function URL for direct HTTPS invocation (null if disabled) |

## Security Features

- **KMS encryption**: Environment variables and CloudWatch logs encrypted at rest with customer-managed KMS keys
- **Least-privilege IAM**: Only `AWSLambdaBasicExecutionRole` attached by default; VPC and X-Ray policies added conditionally
- **VPC isolation**: Optional deployment into private subnets for network boundary protection
- **X-Ray tracing**: Active tracing enabled by default for full request visibility and anomaly detection
- **Dead-letter queue**: Optional DLQ for capturing and auditing failed asynchronous invocations
- **Log retention**: Configurable retention period with CloudWatch-validated values
- **Function URL auth**: Defaults to `AWS_IAM` authorization to prevent unauthenticated access
