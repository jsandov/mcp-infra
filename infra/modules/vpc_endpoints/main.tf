# -----------------------------------------------------------------------------
# S3 Gateway VPC Endpoint
# -----------------------------------------------------------------------------

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  policy            = var.s3_endpoint_policy

  route_table_ids = var.route_table_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-s3-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

# -----------------------------------------------------------------------------
# DynamoDB Gateway VPC Endpoint
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  policy            = var.dynamodb_endpoint_policy

  route_table_ids = var.route_table_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-dynamodb-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

# -----------------------------------------------------------------------------
# Interface VPC Endpoints
# These eliminate NAT Gateway dependency for AWS service calls from Lambda in VPC
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_sts_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-sts-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

resource "aws_vpc_endpoint" "kms" {
  count = var.enable_kms_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-kms-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

resource "aws_vpc_endpoint" "logs" {
  count = var.enable_logs_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-logs-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_api_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-ecr-api-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_dkr_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-ecr-dkr-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}

resource "aws_vpc_endpoint" "xray" {
  count = var.enable_xray_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.xray"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-xray-endpoint"
    Environment = var.environment
    ManagedBy   = "opentofu"
  })
}
