output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (empty if NAT is disabled)"
  value       = aws_nat_gateway.this[*].id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
}

output "default_security_group_id" {
  description = "The ID of the default security group (deny-all)"
  value       = aws_default_security_group.this.id
}

output "flow_log_id" {
  description = "The ID of the VPC Flow Log (null if flow logs are disabled)"
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_group_name" {
  description = "The CloudWatch Log Group name for VPC Flow Logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}
