output "alb_id" {
  description = "The ID of the ALB"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB (for Route 53 alias records)"
  value       = aws_lb.this.zone_id
}

output "default_target_group_arn" {
  description = "The ARN of the default target group"
  value       = aws_lb_target_group.default.arn
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener (null if no certificate provided)"
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "waf_acl_association_id" {
  description = "The ID of the WAF ACL association (null if WAF not attached)"
  value       = try(aws_wafv2_web_acl_association.this[0].id, null)
}
