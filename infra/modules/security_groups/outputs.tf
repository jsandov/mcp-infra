output "web_security_group_id" {
  description = "The ID of the web tier security group (null if not created)"
  value       = try(aws_security_group.web[0].id, null)
}

output "web_security_group_arn" {
  description = "The ARN of the web tier security group (null if not created)"
  value       = try(aws_security_group.web[0].arn, null)
}

output "app_security_group_id" {
  description = "The ID of the application tier security group (null if not created)"
  value       = try(aws_security_group.app[0].id, null)
}

output "app_security_group_arn" {
  description = "The ARN of the application tier security group (null if not created)"
  value       = try(aws_security_group.app[0].arn, null)
}

output "db_security_group_id" {
  description = "The ID of the database tier security group (null if not created)"
  value       = try(aws_security_group.db[0].id, null)
}

output "db_security_group_arn" {
  description = "The ARN of the database tier security group (null if not created)"
  value       = try(aws_security_group.db[0].arn, null)
}

output "bastion_security_group_id" {
  description = "The ID of the bastion host security group (null if not created)"
  value       = try(aws_security_group.bastion[0].id, null)
}

output "bastion_security_group_arn" {
  description = "The ARN of the bastion host security group (null if not created)"
  value       = try(aws_security_group.bastion[0].arn, null)
}
