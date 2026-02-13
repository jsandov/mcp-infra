# Security Groups Module

Creates reusable security groups for common infrastructure tiers: web, application, database, and bastion. Each tier is independently toggleable and follows a layered access pattern where each tier only accepts traffic from the tier above it.

## Architecture

```
Internet --> [Web SG: 80, 443] --> [App SG: app_port] --> [DB SG: db_port]
                                        ^
            [Bastion SG: 22] -----------|
```

## Usage

### Basic (unrestricted egress)

```hcl
module "security_groups" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/security_groups?ref=v1.0.0"

  vpc_id      = module.vpc.vpc_id
  environment = "dev"

  create_web_sg     = true
  create_app_sg     = true
  create_db_sg      = true
  create_bastion_sg = true

  app_port              = 8080
  db_port               = 5432
  bastion_allowed_cidrs = ["203.0.113.0/24"]

  restrict_egress = false
  vpc_cidr_block  = "10.0.0.0/16"

  tags = {
    Project = "my-project"
  }
}
```

### Production (restricted egress, default)

```hcl
module "security_groups" {
  source = "git::https://github.com/jsandov/cloud-voyager-infra.git//infra/modules/security_groups?ref=v1.0.0"

  vpc_id      = module.vpc.vpc_id
  environment = "prod"

  create_web_sg     = true
  create_app_sg     = true
  create_db_sg      = true
  create_bastion_sg = true

  app_port              = 8080
  db_port               = 5432
  bastion_allowed_cidrs = ["203.0.113.0/24"]
  vpc_cidr_block        = "10.0.0.0/16"

  tags = {
    Project = "my-project"
  }
}
```

When `restrict_egress = true`, each tier's outbound traffic is limited to only the ports it needs:

| Tier    | Allowed egress                                                      |
| ------- | ------------------------------------------------------------------- |
| Web     | HTTPS (443/tcp), DNS (53/tcp+udp), NTP (123/udp)                   |
| App     | DB port to DB SG, HTTPS (443/tcp), DNS (53/tcp+udp), NTP (123/udp) |
| DB      | DNS (53/tcp+udp), NTP (123/udp) only                               |
| Bastion | SSH (22/tcp) to VPC CIDR, DNS (53/tcp+udp), NTP (123/udp)          |

When bastion and app SGs are both enabled, an ingress rule is automatically added to the app SG allowing SSH (port 22) from the bastion SG.

## Inputs

| Name                    | Type           | Default         | Required | Description                                                  |
| ----------------------- | -------------- | --------------- | -------- | ------------------------------------------------------------ |
| `vpc_id`                | `string`       | --              | yes      | The VPC to create security groups in                         |
| `environment`           | `string`       | --              | yes      | Environment name for tagging (dev, staging, prod)            |
| `create_web_sg`         | `bool`         | `true`          | no       | Create the web tier security group                           |
| `create_app_sg`         | `bool`         | `true`          | no       | Create the application tier security group                   |
| `create_db_sg`          | `bool`         | `true`          | no       | Create the database tier security group                      |
| `create_bastion_sg`     | `bool`         | `false`         | no       | Create the bastion host security group                       |
| `app_port`              | `number`       | `8080`          | no       | Port the application listens on                              |
| `db_port`               | `number`       | `5432`          | no       | Port the database listens on                                 |
| `web_ingress_cidrs`     | `list(string)` | `["0.0.0.0/0"]` | no       | CIDRs allowed to reach web tier on HTTP/HTTPS                |
| `bastion_allowed_cidrs` | `list(string)` | `[]`            | no       | CIDRs allowed to SSH to bastion hosts                        |
| `restrict_egress`       | `bool`         | `true`          | no       | Restrict egress to minimum required ports per tier (SC-7)    |
| `vpc_cidr_block`        | `string`       | `""`            | no       | VPC CIDR block (used for bastion SSH egress when restricted) |
| `tags`                  | `map(string)`  | `{}`            | no       | Additional tags for all resources                            |

## Outputs

| Name                         | Description                                              |
| ---------------------------- | -------------------------------------------------------- |
| `web_security_group_id`      | The ID of the web tier security group (null if skipped)  |
| `web_security_group_arn`     | The ARN of the web tier security group (null if skipped) |
| `app_security_group_id`      | The ID of the app tier security group (null if skipped)  |
| `app_security_group_arn`     | The ARN of the app tier security group (null if skipped) |
| `db_security_group_id`       | The ID of the DB tier security group (null if skipped)   |
| `db_security_group_arn`      | The ARN of the DB tier security group (null if skipped)  |
| `bastion_security_group_id`  | The ID of the bastion security group (null if skipped)   |
| `bastion_security_group_arn` | The ARN of the bastion security group (null if skipped)  |

## Security Design

- **Layered access**: Each tier only accepts ingress from the tier above it (FedRAMP SC-7)
- **Egress control**: Egress is restricted by default to minimum required ports per tier (HTTPS, DNS, NTP, and tier-specific ports). Set `restrict_egress = false` to allow all outbound traffic in non-compliance environments
- **Bastion is off by default**: Must explicitly enable and provide allowed CIDRs. A safety check warns if `0.0.0.0/0` is used
- **Bastion-to-app access**: When both bastion and app SGs are enabled, SSH ingress from bastion to app tier is automatically configured
- **All rules have descriptions**: Required for compliance and auditability
- **`name_prefix` with `create_before_destroy`**: Prevents downtime during SG replacement
- **`revoke_rules_on_delete`**: Enabled on all SGs to prevent deletion failures from cross-SG references
- **Configurable web ingress CIDRs**: Web tier ingress defaults to `0.0.0.0/0` but can be restricted to CloudFront or ALB CIDRs
