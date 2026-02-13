# -----------------------------------------------------------------------------
# CloudFront + WAF Module
# Provides Layer 7 protection for HTTP API v2 endpoints that cannot
# directly associate with WAFv2 (FedRAMP SC-7).
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.environment}-${var.name}"
  origin_id   = "${local.name_prefix}-api-gateway"

  api_domain = replace(replace(var.api_gateway_endpoint, "https://", ""), "/", "")

  default_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name_prefix} CloudFront distribution protecting API Gateway"
  price_class     = var.price_class
  web_acl_id      = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null

  aliases = var.custom_domain_name != null ? [var.custom_domain_name] : []

  origin {
    domain_name = local.api_domain
    origin_id   = local.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id
    compress         = true

    viewer_protocol_policy = "redirect-to-https"

    # CachingDisabled — API responses should not be cached
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # AllViewerExceptHostHeader — forward all headers except Host
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == null
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = var.certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.certificate_arn != null ? "TLSv1.2_2021" : null
  }

  dynamic "logging_config" {
    for_each = var.enable_logging && var.log_bucket_domain_name != null ? [1] : []
    content {
      bucket          = var.log_bucket_domain_name
      prefix          = var.log_prefix
      include_cookies = false
    }
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-cloudfront"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# WAFv2 Web ACL (FedRAMP SC-7)
# Scope: CLOUDFRONT — must be created in us-east-1
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "this" {
  count = var.enable_waf ? 1 : 0

  name        = "${local.name_prefix}-waf"
  description = "WAFv2 Web ACL protecting ${local.name_prefix} CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # OWASP common threats
  rule {
    name     = "aws-common-rules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Known bad inputs (Log4j, etc.)
  rule {
    name     = "aws-known-bad-inputs"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Bot management
  rule {
    name     = "aws-bot-control"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-bot-control"
      sampled_requests_enabled   = true
    }
  }

  # IP reputation
  rule {
    name     = "aws-ip-reputation"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # IP-based rate limiting
  rule {
    name     = "rate-limit"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-waf"
    FedRAMP = "SC-7"
  })
}

# -----------------------------------------------------------------------------
# WAF Logging (conditional)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_waf ? 1 : 0

  # WAF logging requires the log group name to start with aws-waf-logs-
  name              = "aws-waf-logs-${local.name_prefix}"
  retention_in_days = 90
  kms_key_id        = var.kms_key_arn

  tags = merge(local.default_tags, {
    Name = "aws-waf-logs-${local.name_prefix}"
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_waf ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
  resource_arn            = aws_wafv2_web_acl.this[0].arn
}
