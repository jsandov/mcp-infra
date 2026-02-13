# ---------------------------------------------------------------------------
# MCP Token Vending Machine Module — main.tf
# FedRAMP-compliant tenant-scoped IAM credentials via STS (AC-6, SC-7)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  name_prefix = "${var.environment}-${var.name}"

  default_tags = {
    Name        = "${local.name_prefix}-tvm"
    Environment = var.environment
    ManagedBy   = "opentofu"
  }

  tags = merge(local.default_tags, var.tags)
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# IAM Policy: STS Assume Role for Lambda (AC-6)
# ---------------------------------------------------------------------------
# This inline policy is attached to the MCP server Lambda execution role.
# It allows the Lambda function to assume tenant roles matching the
# configured ARN pattern and tag sessions with tenant context.

resource "aws_iam_role_policy" "sts_assume_tenant_role" {
  name = "${local.name_prefix}-tvm-sts-assume"
  role = var.lambda_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeTenantRole"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = [var.tenant_role_arn_pattern]
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Permission Boundary Policy (AC-6)
# ---------------------------------------------------------------------------
# Maximum permissions any tenant role can ever have. This is a safety net —
# even if a tenant role policy is misconfigured, it cannot exceed these
# permissions. The actual tenant role policies must be narrower than this
# boundary. Only the specific actions listed in var.allowed_actions are
# permitted; no wildcard IAM actions are used.

resource "aws_iam_policy" "tenant_permission_boundary" {
  name        = "${local.name_prefix}-tvm-permission-boundary"
  description = "Permission boundary for MCP tenant roles — limits maximum allowed actions (FedRAMP AC-6)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowedTenantActions"
        Effect = "Allow"
        Action = var.allowed_actions
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/tenant-id" = "$${aws:PrincipalTag/tenant-id}"
          }
        }
      },
      {
        Sid    = "DenyIAMEscalation"
        Effect = "Deny"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreateUser",
          "iam:CreateAccessKey",
          "iam:CreatePolicyVersion",
          "sts:AssumeRole"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "AllowKMSForEncryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn != null ? [var.kms_key_arn] : []
      }
    ]
  })

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Template Tenant Role (conditional)
# ---------------------------------------------------------------------------
# A reference role that demonstrates the correct configuration for tenant
# roles. Organizations use this as a template to create per-tenant roles.
# The role includes the permission boundary and requires a tenant-id
# session tag when assuming the role.

resource "aws_iam_role" "tenant_template" {
  count = var.enable_template_role ? 1 : 0

  name                 = "${local.name_prefix}-tvm-tenant-template"
  permissions_boundary = aws_iam_policy.tenant_permission_boundary.arn
  max_session_duration = var.tenant_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.lambda_role_arn
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Condition = {
          StringLike = {
            "aws:RequestTag/tenant-id" = "*"
          }
        }
      }
    ]
  })

  tags = local.tags
}
