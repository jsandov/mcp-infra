# -----------------------------------------------------------------------------
# Web Tier Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "web" {
  count = var.create_web_sg ? 1 : 0

  name_prefix = "${var.environment}-web-"
  description = "Security group for web tier - allows HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
    ManagedBy   = "opentofu"
    Tier        = "web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_http_ingress" {
  count = var.create_web_sg ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from internet"
  security_group_id = aws_security_group.web[0].id
}

resource "aws_security_group_rule" "web_https_ingress" {
  count = var.create_web_sg ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from internet"
  security_group_id = aws_security_group.web[0].id
}

resource "aws_security_group_rule" "web_egress" {
  count = var.create_web_sg ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.web[0].id
}

# -----------------------------------------------------------------------------
# Application Tier Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  count = var.create_app_sg ? 1 : 0

  name_prefix = "${var.environment}-app-"
  description = "Security group for application tier - allows traffic from web tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.environment}-app-sg"
    Environment = var.environment
    ManagedBy   = "opentofu"
    Tier        = "app"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_from_web" {
  count = var.create_app_sg && var.create_web_sg ? 1 : 0

  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web[0].id
  description              = "Allow traffic from web tier on app port"
  security_group_id        = aws_security_group.app[0].id
}

resource "aws_security_group_rule" "app_egress" {
  count = var.create_app_sg ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.app[0].id
}

# -----------------------------------------------------------------------------
# Database Tier Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "db" {
  count = var.create_db_sg ? 1 : 0

  name_prefix = "${var.environment}-db-"
  description = "Security group for database tier - allows traffic from app tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
    ManagedBy   = "opentofu"
    Tier        = "db"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "db_from_app" {
  count = var.create_db_sg && var.create_app_sg ? 1 : 0

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app[0].id
  description              = "Allow traffic from app tier on database port"
  security_group_id        = aws_security_group.db[0].id
}

resource "aws_security_group_rule" "db_egress" {
  count = var.create_db_sg ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.db[0].id
}

# -----------------------------------------------------------------------------
# Bastion Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name_prefix = "${var.environment}-bastion-"
  description = "Security group for bastion hosts - allows SSH from allowed CIDRs"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.environment}-bastion-sg"
    Environment = var.environment
    ManagedBy   = "opentofu"
    Tier        = "bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion_ssh_ingress" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.bastion_allowed_cidrs
  description       = "Allow SSH from allowed CIDRs"
  security_group_id = aws_security_group.bastion[0].id
}

resource "aws_security_group_rule" "bastion_egress" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.bastion[0].id
}
