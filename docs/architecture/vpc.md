# VPC Architecture

```mermaid
flowchart TB
    Internet(["Internet"])

    subgraph AWS["AWS Region (var.aws_region)"]
        IGW["Internet Gateway<br/><i>aws_internet_gateway.this</i>"]

        subgraph VPC["VPC — var.cidr_block<br/><i>aws_vpc.this</i><br/>DNS Support ✓ | DNS Hostnames ✓"]

            subgraph Defaults["Default Resources (deny-all)"]
                DefSG["Default Security Group<br/>No ingress | No egress"]
                DefNACL["Default Network ACL<br/>No rules"]
                DefRT["Default Route Table<br/>No routes"]
            end

            subgraph PublicRT["Public Route Table<br/>0.0.0.0/0 → IGW"]
            end

            subgraph AZ1["Availability Zone 1"]
                PubSub1["Public Subnet<br/>map_public_ip: var"]
                PrivSub1["Private Subnet"]
                NAT1["NAT GW + EIP"]
                PrivRT1["Private RT 1<br/>0.0.0.0/0 → NAT1"]
            end

            subgraph AZ2["Availability Zone 2"]
                PubSub2["Public Subnet<br/>map_public_ip: var"]
                PrivSub2["Private Subnet"]
                NAT2["NAT GW + EIP<br/>(multi-AZ only)"]
                PrivRT2["Private RT 2<br/>(multi-AZ only)"]
            end

            subgraph AZ3["Availability Zone 3"]
                PubSub3["Public Subnet<br/>map_public_ip: var"]
                PrivSub3["Private Subnet"]
                NAT3["NAT GW + EIP<br/>(multi-AZ only)"]
                PrivRT3["Private RT 3<br/>(multi-AZ only)"]
            end
        end

        subgraph FlowLogs["VPC Flow Logs (conditional)"]
            FL["Flow Log — Traffic: ALL"]
            CWLog["CloudWatch Log Group<br/>Optional KMS encryption"]
            FLRole["IAM Role (least-privilege)"]
        end
    end

    Internet <-->|"inbound/outbound"| IGW
    IGW --- PublicRT

    PublicRT --- PubSub1
    PublicRT --- PubSub2
    PublicRT --- PubSub3

    NAT1 -.->|"placed in"| PubSub1
    NAT2 -.->|"placed in"| PubSub2
    NAT3 -.->|"placed in"| PubSub3

    PrivRT1 --- PrivSub1
    PrivRT2 --- PrivSub2
    PrivRT3 --- PrivSub3

    NAT1 --- PrivRT1
    NAT2 --- PrivRT2
    NAT3 --- PrivRT3

    VPC -.->|"logs traffic"| FL
    FL --> CWLog
    FL -.->|"assumes"| FLRole
```

## NAT Gateway Modes

| Mode | `single_nat_gateway` | Resources Created | Recommended For |
| --- | --- | --- | --- |
| Single (default) | `true` | 1 NAT GW, 1 EIP, 1 Private RT | Dev/Staging |
| Multi-AZ HA | `false` | 1 NAT GW + EIP + RT per AZ | Production |

## Design Decisions

- **Default resources managed with deny-all** — prevents use of AWS default SG/NACL/RT which have permissive rules
- **Configurable NAT topology**: Single NAT for cost savings, per-AZ NAT for high availability
- **Configurable `map_public_ip_on_launch`** — defaults to `true`, set `false` to prevent auto-assign
- **Subnet CIDRs** computed dynamically via `cidrsubnet()` in root config
- **3 AZs** selected automatically from available zones in the region
- **VPC Flow Logs** enabled by default for security monitoring
