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

            subgraph PrivateRT["Private Route Table<br/>0.0.0.0/0 → NAT (if enabled)"]
            end

            subgraph AZ1["Availability Zone 1"]
                PubSub1["Public Subnet<br/>cidrsubnet(cidr, 8, 1)"]
                PrivSub1["Private Subnet<br/>cidrsubnet(cidr, 8, 11)"]
            end

            subgraph AZ2["Availability Zone 2"]
                PubSub2["Public Subnet<br/>cidrsubnet(cidr, 8, 2)"]
                PrivSub2["Private Subnet<br/>cidrsubnet(cidr, 8, 12)"]
            end

            subgraph AZ3["Availability Zone 3"]
                PubSub3["Public Subnet<br/>cidrsubnet(cidr, 8, 3)"]
                PrivSub3["Private Subnet<br/>cidrsubnet(cidr, 8, 13)"]
            end

            NAT["NAT Gateway (conditional)<br/>Placed in Public Subnet AZ1"]
            EIP["Elastic IP"]
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

    EIP --- NAT
    NAT -.->|"placed in"| PubSub1
    NAT --- PrivateRT

    PrivateRT --- PrivSub1
    PrivateRT --- PrivSub2
    PrivateRT --- PrivSub3

    VPC -.->|"logs traffic"| FL
    FL --> CWLog
    FL -.->|"assumes"| FLRole
```

## Design Decisions

- **Default resources managed with deny-all** — prevents use of AWS default SG/NACL/RT which have permissive rules
- **Single NAT Gateway** in AZ1 for cost efficiency — suitable for dev/staging
- **Subnet CIDRs** computed dynamically via `cidrsubnet()` in root config
- **3 AZs** selected automatically from available zones in the region
- **VPC Flow Logs** enabled by default for security monitoring
