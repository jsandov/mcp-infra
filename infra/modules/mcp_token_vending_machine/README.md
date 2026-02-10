# MCP Token Vending Machine Module

The Token Vending Machine (TVM) module implements tenant-scoped IAM credentials for multi-tenant MCP server deployments. It uses the AWS STS AssumeRole pattern to provide short-lived, least-privilege credentials scoped to individual tenants.

This module is designed for FedRAMP-compliant environments and enforces strict access controls through permission boundaries, explicit IAM actions (no wildcards), and session tagging.

## Architecture

```
MCP Server Lambda (execution role)
    |
    | sts:AssumeRole + sts:TagSession
    | (with tenant-id session tag)
    v
Tenant IAM Role (one per tenant, all follow same pattern)
    |
    | Permission boundary limits max permissions
    v
Tenant Resources (S3 bucket, DynamoDB table, Secrets Manager, etc.)
```

### How It Works

1. The MCP server Lambda receives a request with a JWT containing a tenant identifier.
2. The Lambda extracts the `tenant-id` from the JWT claims.
3. Using its execution role, the Lambda calls `sts:AssumeRole` on the tenant-specific IAM role, passing `tenant-id` as a session tag.
4. STS returns short-lived credentials scoped to that tenant's role.
5. The tenant role's permission boundary ensures credentials can only access resources tagged with the matching `tenant-id`.

## Usage

### Minimal Example

```hcl
module "tvm" {
  source = "git::https://github.com/<org>/cloud-voyager-infra.git//infra/modules/mcp_token_vending_machine?ref=v1.0.0"

  name                    = "mcp-server"
  environment             = "dev"
  lambda_role_arn         = aws_iam_role.mcp_lambda.arn
  lambda_role_name        = aws_iam_role.mcp_lambda.name
  tenant_role_arn_pattern = "arn:aws:iam::123456789012:role/mcp-tenant-*"
}
```

### Production Example

```hcl
module "tvm" {
  source = "git::https://github.com/<org>/cloud-voyager-infra.git//infra/modules/mcp_token_vending_machine?ref=v1.0.0"

  name                    = "mcp-server"
  environment             = "prod"
  lambda_role_arn         = aws_iam_role.mcp_lambda.arn
  lambda_role_name        = aws_iam_role.mcp_lambda.name
  tenant_role_arn_pattern = "arn:aws:iam::123456789012:role/mcp-tenant-*"

  allowed_actions = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:ListBucket",
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:Query",
    "secretsmanager:GetSecretValue",
  ]

  kms_key_arn            = aws_kms_key.tenant_data.arn
  enable_template_role   = true
  tenant_session_duration = 1800

  tags = {
    Team    = "platform"
    Service = "mcp-server"
  }
}
```

## How Tenants Are Isolated

Tenant isolation is achieved through multiple layers:

1. **JWT-based identity**: The MCP server Lambda extracts the `tenant-id` from the incoming JWT token. This establishes the caller's tenant context.

2. **STS session tags**: When assuming a tenant role, the Lambda passes `tenant-id` as a session tag via `sts:TagSession`. This tag becomes part of the temporary credentials.

3. **IAM condition keys**: The permission boundary uses `aws:PrincipalTag/tenant-id` conditions to ensure that actions can only be performed on resources matching the caller's tenant. Resource policies and tenant role policies should also enforce this condition.

4. **Permission boundary ceiling**: The permission boundary defines the absolute maximum permissions. Even if a tenant role policy grants broader access, the boundary prevents escalation.

5. **IAM escalation denial**: The permission boundary explicitly denies IAM and STS actions that could be used to escalate privileges, such as creating roles, attaching policies, or assuming other roles.

## Creating Tenant Roles

To create a per-tenant IAM role, follow this pattern:

### Step 1: Create the Tenant Role

```hcl
resource "aws_iam_role" "tenant_acme" {
  name                 = "mcp-tenant-acme"
  permissions_boundary = module.tvm.permission_boundary_arn
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.mcp_lambda.arn
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/tenant-id" = "acme"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "mcp-tenant-acme"
    Environment = "prod"
    ManagedBy   = "opentofu"
    TenantId    = "acme"
  }
}
```

### Step 2: Attach a Tenant-Specific Policy

```hcl
resource "aws_iam_role_policy" "tenant_acme_data" {
  name = "mcp-tenant-acme-data-access"
  role = aws_iam_role.tenant_acme.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::my-data-bucket/tenants/acme/*"
        ]
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:us-east-1:123456789012:table/tenant-data"
        ]
        Condition = {
          "ForAllValues:StringEquals" = {
            "dynamodb:LeadingKeys" = ["acme"]
          }
        }
      }
    ]
  })
}
```

### Key Points

- The role name must match the `tenant_role_arn_pattern` (e.g., `mcp-tenant-*`).
- Always attach the permission boundary from this module's output.
- Use `StringEquals` (not `StringLike`) in the trust policy condition to bind the role to a specific tenant.
- Scope resource ARNs as narrowly as possible in tenant policies.

## FedRAMP Controls

| Control | Description | Implementation |
|---------|-------------|----------------|
| AC-6 | Least Privilege | Permission boundary limits maximum actions; explicit action lists (no wildcards); tenant-scoped resource access via session tags |
| AC-2 | Account Management | Template role pattern for consistent tenant provisioning; trust policies restrict which principals can assume roles |
| SC-7 | Boundary Protection | Permission boundary acts as a security boundary; IAM escalation actions are explicitly denied; STS session duration is configurable and bounded |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name identifier for TVM resources (1-40 chars, lowercase, numbers, hyphens) | `string` | n/a | yes |
| `environment` | Deployment environment (dev, staging, prod) | `string` | n/a | yes |
| `tags` | Additional tags to apply to all TVM resources | `map(string)` | `{}` | no |
| `lambda_role_arn` | ARN of the MCP server Lambda execution role | `string` | n/a | yes |
| `lambda_role_name` | Name of the MCP server Lambda execution role | `string` | n/a | yes |
| `tenant_role_arn_pattern` | ARN pattern for tenant roles the Lambda can assume | `string` | n/a | yes |
| `allowed_actions` | IAM actions allowed in the tenant permission boundary | `list(string)` | See variables.tf | no |
| `kms_key_arn` | KMS key ARN for encryption operations in the permission boundary | `string` | `null` | no |
| `enable_template_role` | Whether to create a template tenant IAM role | `bool` | `true` | no |
| `tenant_session_duration` | Max session duration for tenant roles in seconds (900-43200) | `number` | `3600` | no |

## Outputs

| Name | Description |
|------|-------------|
| `sts_policy_name` | Name of the inline IAM policy granting STS assume-role permissions |
| `permission_boundary_arn` | ARN of the permission boundary policy for tenant roles |
| `permission_boundary_name` | Name of the permission boundary policy |
| `template_role_arn` | ARN of the template tenant role (null if disabled) |
| `template_role_name` | Name of the template tenant role (null if disabled) |

## Design Decisions

### Why Permission Boundaries?

Permission boundaries provide a hard ceiling on what any tenant role can do, regardless of the policies attached to it. This is critical in multi-tenant environments where tenant roles may be created by automation or less-trusted processes. The boundary ensures that even a misconfigured tenant role cannot exceed the defined limits.

### Why Session Tags?

STS session tags allow the MCP server Lambda to pass tenant context (the `tenant-id`) into the assumed role's credentials. IAM policies can then use `aws:PrincipalTag/tenant-id` conditions to scope access to tenant-specific resources. This provides row-level and prefix-level isolation without creating separate AWS accounts per tenant.

### Why Explicit Actions Instead of Wildcards?

This module follows the project convention of never using wildcard IAM actions (`service:*`). Every permitted action is explicitly listed in `var.allowed_actions`. This approach:

- Makes the permission surface auditable and reviewable.
- Prevents accidental exposure of dangerous operations (e.g., `s3:DeleteBucket`).
- Satisfies FedRAMP AC-6 least privilege requirements.
- Allows fine-grained control over what tenants can do.

The `allowed_actions` variable includes a validation rule that rejects wildcard patterns, enforcing this constraint at plan time.

### Why a Template Role?

The optional template role serves as a reference implementation for tenant roles. It demonstrates the correct trust policy, permission boundary attachment, and session duration configuration. Platform teams can use it as a starting point when automating tenant onboarding.
