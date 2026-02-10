output "bucket_id" {
  description = "The name of the S3 state bucket"
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "The ARN of the S3 state bucket"
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "The name of the DynamoDB lock table"
  value       = aws_dynamodb_table.lock.name
}

output "lock_table_arn" {
  description = "The ARN of the DynamoDB lock table"
  value       = aws_dynamodb_table.lock.arn
}

output "backend_config" {
  description = "Backend configuration block for copy-paste into versions.tf"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.state.id}"
      key            = "mcp-infra/terraform.tfstate"
      region         = "${data.aws_region.current.name}"
      encrypt        = true
      dynamodb_table = "${aws_dynamodb_table.lock.name}"
    }
  EOT
}

data "aws_region" "current" {}
