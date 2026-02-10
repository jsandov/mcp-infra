# Infrastructure Architecture

This diagram represents the AWS VPC infrastructure provisioned by the `infra/modules/vpc` module.

## VPC Network Topology

```mermaid
flowchart TB
    Internet(["Internet"])

    subgraph AWS["AWS Region (var.aws_region)"]
        IGW["Internet Gateway<br/><i>aws_internet_gateway.this</i>"]

        subgraph VPC["VPC — var.cidr_block (default: 10.0.0.0/16)<br/><i>aws_vpc.this</i><br/>DNS Support ✓ | DNS Hostnames ✓"]

            subgraph PublicRT["Public Route Table<br/><i>aws_route_table.public</i><br/>0.0.0.0/0 → IGW"]
            end

            subgraph PrivateRT["Private Route Table<br/><i>aws_route_table.private</i><br/>0.0.0.0/0 → NAT (if enabled)"]
            end

            subgraph AZ1["Availability Zone 1"]
                PubSub1["Public Subnet<br/>10.0.1.0/24<br/><i>map_public_ip = true</i>"]
                PrivSub1["Private Subnet<br/>10.0.11.0/24"]
            end

            subgraph AZ2["Availability Zone 2"]
                PubSub2["Public Subnet<br/>10.0.2.0/24<br/><i>map_public_ip = true</i>"]
                PrivSub2["Private Subnet<br/>10.0.12.0/24"]
            end

            subgraph AZ3["Availability Zone 3"]
                PubSub3["Public Subnet<br/>10.0.3.0/24<br/><i>map_public_ip = true</i>"]
                PrivSub3["Private Subnet<br/>10.0.13.0/24"]
            end

            NAT["NAT Gateway<br/><i>aws_nat_gateway.this</i><br/>(conditional: var.enable_nat_gateway)<br/>Placed in Public Subnet AZ1"]
            EIP["Elastic IP<br/><i>aws_eip.nat</i>"]
        end
    end

    %% Internet to VPC
    Internet <-->|"inbound/outbound"| IGW
    IGW --- PublicRT

    %% Public route table associations
    PublicRT --- PubSub1
    PublicRT --- PubSub2
    PublicRT --- PubSub3

    %% NAT Gateway
    EIP --- NAT
    NAT -.->|"placed in"| PubSub1
    NAT --- PrivateRT

    %% Private route table associations
    PrivateRT --- PrivSub1
    PrivateRT --- PrivSub2
    PrivateRT --- PrivSub3

    %% Styling
    style Internet fill:#f9f,stroke:#333,stroke-width:2px
    style VPC fill:#e8f4f8,stroke:#1a73e8,stroke-width:2px
    style AZ1 fill:#fff3e0,stroke:#e65100,stroke-width:1px
    style AZ2 fill:#fff3e0,stroke:#e65100,stroke-width:1px
    style AZ3 fill:#fff3e0,stroke:#e65100,stroke-width:1px
    style PubSub1 fill:#c8e6c9,stroke:#2e7d32
    style PubSub2 fill:#c8e6c9,stroke:#2e7d32
    style PubSub3 fill:#c8e6c9,stroke:#2e7d32
    style PrivSub1 fill:#bbdefb,stroke:#1565c0
    style PrivSub2 fill:#bbdefb,stroke:#1565c0
    style PrivSub3 fill:#bbdefb,stroke:#1565c0
    style IGW fill:#fff9c4,stroke:#f57f17
    style NAT fill:#fff9c4,stroke:#f57f17
    style EIP fill:#fff9c4,stroke:#f57f17
    style PublicRT fill:#e8eaf6,stroke:#283593
    style PrivateRT fill:#e8eaf6,stroke:#283593
```

## Resource Summary

| Resource | Count | Conditional |
| --- | --- | --- |
| `aws_vpc` | 1 | No |
| `aws_internet_gateway` | 1 | No |
| `aws_subnet` (public) | 3 (one per AZ) | No |
| `aws_subnet` (private) | 3 (one per AZ) | No |
| `aws_route_table` (public) | 1 | No |
| `aws_route_table` (private) | 1 | No |
| `aws_route` (public → IGW) | 1 | No |
| `aws_route` (private → NAT) | 1 | `var.enable_nat_gateway` |
| `aws_route_table_association` (public) | 3 | No |
| `aws_route_table_association` (private) | 3 | No |
| `aws_nat_gateway` | 1 | `var.enable_nat_gateway` |
| `aws_eip` | 1 | `var.enable_nat_gateway` |

## Key Design Decisions

- **Single NAT Gateway** in AZ1 for cost efficiency — suitable for dev/staging. For production HA, deploy one NAT per AZ.
- **Subnet CIDRs** computed dynamically via `cidrsubnet()` — public subnets use offsets 1-3, private subnets use offsets 11-13.
- **3 AZs** selected automatically from available zones in the region via `data.aws_availability_zones`.
- **NAT Gateway** is conditional (`var.enable_nat_gateway`, default `false`) to avoid cost when not needed.
- **Default tags** (`ManagedBy = "opentofu"`, `Environment`) applied at both provider level and resource level.
