# Security Groups Module

Creates reusable security groups for common infrastructure tiers: web, application, database, and bastion. Each tier is independently toggleable and follows a layered access pattern where each tier only accepts traffic from the tier above it.

## Architecture

```
Internet --> [Web SG: 80, 443] --> [App SG: app_port] --> [DB SG: db_port]
                                        ^
            [Bastion SG: 22] -----------|
```

## Usage

```hcl
module "security_groups" {
  source = "git::https://github.com/<org>/mcp-infra.git//infra/modules/security_groups?ref=v1.0.0"

  vpc_id      = module.vpc.vpc_id
  environment = "dev"

  create_web_sg     = true
  create_app_sg     = true
  create_db_sg      = true
  create_bastion_sg = true

  app_port             = 8080
  db_port              = 5432
  bastion_allowed_cidrs = ["203.0.113.0/24"]

  tags = {
    Project = "my-project"
  }
}
```

## Inputs

| Name                    | Type           | Default   | Required | Description                                              |
| ----------------------- | -------------- | --------- | -------- | -------------------------------------------------------- |
| `vpc_id`                | `string`       | —         | yes      | The VPC to create security groups in                     |
| `environment`           | `string`       | —         | yes      | Environment name for tagging (dev, staging, prod)        |
| `create_web_sg`         | `bool`         | `true`    | no       | Create the web tier security group                       |
| `create_app_sg`         | `bool`         | `true`    | no       | Create the application tier security group               |
| `create_db_sg`          | `bool`         | `true`    | no       | Create the database tier security group                  |
| `create_bastion_sg`     | `bool`         | `false`   | no       | Create the bastion host security group                   |
| `app_port`              | `number`       | `8080`    | no       | Port the application listens on                          |
| `db_port`               | `number`       | `5432`    | no       | Port the database listens on                             |
| `bastion_allowed_cidrs` | `list(string)` | `[]`      | no       | CIDRs allowed to SSH to bastion hosts                    |
| `tags`                  | `map(string)`  | `{}`      | no       | Additional tags for all resources                        |

## Outputs

| Name                       | Description                                             |
| -------------------------- | ------------------------------------------------------- |
| `web_security_group_id`    | The ID of the web tier security group (null if skipped) |
| `app_security_group_id`    | The ID of the app tier security group (null if skipped) |
| `db_security_group_id`     | The ID of the DB tier security group (null if skipped)  |
| `bastion_security_group_id`| The ID of the bastion security group (null if skipped)  |

## Security Design

- **Layered access**: Each tier only accepts ingress from the tier above it
- **No open egress by default**: All SGs allow outbound traffic (configurable per your needs)
- **Bastion is off by default**: Must explicitly enable and provide allowed CIDRs
- **All rules have descriptions**: Required for compliance and auditability
- **name_prefix with create_before_destroy**: Prevents downtime during SG replacement
