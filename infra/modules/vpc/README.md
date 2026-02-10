# VPC Module

Creates an AWS VPC with public and private subnets across multiple availability zones, an Internet Gateway, an optional NAT Gateway, and optional VPC Flow Logs. Default VPC resources (security group, network ACL, route table) are managed with deny-all rules for security hardening.

## Usage

```hcl
module "vpc" {
  source = "git::https://github.com/<org>/mcp-infra.git//infra/modules/vpc?ref=v1.0.0"

  cidr_block         = "10.0.0.0/16"
  environment        = "dev"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  enable_nat_gateway = false
  enable_flow_logs   = true

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24",
  ]

  tags = {
    Project = "my-project"
  }
}
```

## Inputs

| Name                      | Type           | Default | Required | Description                                              |
| ------------------------- | -------------- | ------- | -------- | -------------------------------------------------------- |
| `cidr_block`              | `string`       | —       | yes      | The CIDR block for the VPC                               |
| `environment`             | `string`       | —       | yes      | Environment name for tagging (dev, staging, prod)        |
| `public_subnet_cidrs`     | `list(string)` | —       | yes      | CIDR blocks for public subnets (one per AZ)              |
| `private_subnet_cidrs`    | `list(string)` | —       | yes      | CIDR blocks for private subnets (one per AZ)             |
| `availability_zones`      | `list(string)` | —       | yes      | AWS availability zones to deploy subnets into            |
| `enable_nat_gateway`      | `bool`         | `false` | no       | Whether to create a NAT Gateway for private subnets      |
| `enable_flow_logs`        | `bool`         | `true`  | no       | Whether to enable VPC Flow Logs                          |
| `flow_log_retention_days` | `number`       | `30`    | no       | Days to retain flow logs in CloudWatch                   |
| `tags`                    | `map(string)`  | `{}`    | no       | Additional tags to apply to all resources                |

## Outputs

| Name                        | Description                                        |
| --------------------------- | -------------------------------------------------- |
| `vpc_id`                    | The ID of the VPC                                  |
| `vpc_cidr_block`            | The CIDR block of the VPC                          |
| `public_subnet_ids`         | List of public subnet IDs                          |
| `private_subnet_ids`        | List of private subnet IDs                         |
| `internet_gateway_id`       | The ID of the Internet Gateway                     |
| `nat_gateway_ids`           | List of NAT Gateway IDs (empty if NAT is disabled) |
| `public_route_table_id`     | The ID of the public route table                   |
| `private_route_table_id`    | The ID of the private route table                  |
| `default_security_group_id` | The ID of the default security group (deny-all)    |
| `flow_log_id`               | The ID of the VPC Flow Log (null if disabled)      |
| `flow_log_group_name`       | CloudWatch Log Group name for flow logs            |
