output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "The domain name of the CloudFront distribution (e.g., d1234.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "The Route53 hosted zone ID for the CloudFront distribution (for alias records)"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "waf_acl_arn" {
  description = "The ARN of the WAFv2 Web ACL (null if WAF disabled)"
  value       = try(aws_wafv2_web_acl.this[0].arn, null)
}

output "waf_acl_id" {
  description = "The ID of the WAFv2 Web ACL (null if WAF disabled)"
  value       = try(aws_wafv2_web_acl.this[0].id, null)
}
