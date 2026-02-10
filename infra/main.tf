data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  cidr_block         = var.vpc_cidr
  environment        = var.environment
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  enable_nat_gateway = var.enable_nat_gateway

  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
    cidrsubnet(var.vpc_cidr, 8, 3),
  ]

  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 11),
    cidrsubnet(var.vpc_cidr, 8, 12),
    cidrsubnet(var.vpc_cidr, 8, 13),
  ]

  tags = {
    Project = "mcp-infra"
  }
}
