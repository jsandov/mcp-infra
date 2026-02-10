# ---------------------------------------------------------------------------
# MCP Token Vending Machine Module — outputs.tf
# ---------------------------------------------------------------------------

output "sts_policy_name" {
  description = "Name of the inline IAM policy granting the Lambda execution role STS assume-role permissions for tenant roles."
  value       = aws_iam_role_policy.sts_assume_tenant_role.name
}

output "permission_boundary_arn" {
  description = "ARN of the permission boundary policy that limits maximum permissions for tenant roles."
  value       = aws_iam_policy.tenant_permission_boundary.arn
}

output "permission_boundary_name" {
  description = "Name of the permission boundary policy for tenant roles."
  value       = aws_iam_policy.tenant_permission_boundary.name
}

output "template_role_arn" {
  description = "ARN of the template tenant role. Null if enable_template_role is false."
  value       = var.enable_template_role ? aws_iam_role.tenant_template[0].arn : null
}

output "template_role_name" {
  description = "Name of the template tenant role. Null if enable_template_role is false."
  value       = var.enable_template_role ? aws_iam_role.tenant_template[0].name : null
}
