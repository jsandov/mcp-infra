output "s3_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "s3_endpoint_prefix_list_id" {
  description = "The prefix list ID of the S3 endpoint for use in security group rules"
  value       = try(aws_vpc_endpoint.s3[0].prefix_list_id, null)
}

output "dynamodb_endpoint_id" {
  description = "The ID of the DynamoDB Gateway VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

output "dynamodb_endpoint_prefix_list_id" {
  description = "The prefix list ID of the DynamoDB endpoint for use in security group rules"
  value       = try(aws_vpc_endpoint.dynamodb[0].prefix_list_id, null)
}

output "sts_endpoint_id" {
  description = "The ID of the STS Interface VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.sts[0].id, null)
}

output "kms_endpoint_id" {
  description = "The ID of the KMS Interface VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.kms[0].id, null)
}

output "logs_endpoint_id" {
  description = "The ID of the CloudWatch Logs Interface VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.logs[0].id, null)
}

output "ecr_api_endpoint_id" {
  description = "The ID of the ECR API Interface VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.ecr_api[0].id, null)
}

output "ecr_dkr_endpoint_id" {
  description = "The ID of the ECR Docker Interface VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.ecr_dkr[0].id, null)
}

output "xray_endpoint_id" {
  description = "The ID of the X-Ray Interface VPC Endpoint (null if disabled)"
  value       = try(aws_vpc_endpoint.xray[0].id, null)
}
