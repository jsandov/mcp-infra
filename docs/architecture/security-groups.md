# Security Groups Architecture

```mermaid
flowchart LR
    Internet(["Internet"]) -->|"80, 443"| WebSG
    BastionCIDRs(["Allowed CIDRs"]) -->|"22"| BastionSG

    subgraph SGs["Security Groups"]
        WebSG["Web Tier SG<br/>Ingress: 80, 443<br/>from 0.0.0.0/0"]
        AppSG["App Tier SG<br/>Ingress: var.app_port<br/>from Web SG only"]
        DBSG["DB Tier SG<br/>Ingress: var.db_port<br/>from App SG only"]
        BastionSG["Bastion SG<br/>Ingress: 22<br/>from allowed CIDRs<br/>(off by default)"]
    end

    WebSG -->|"var.app_port"| AppSG
    AppSG -->|"var.db_port"| DBSG
    BastionSG -.->|"access"| AppSG
```

## Egress Control

When `restrict_egress = true`:

```mermaid
flowchart TB
    subgraph Web["Web Tier Egress"]
        W1["HTTPS (443/tcp)"]
        W2["DNS (53/tcp+udp)"]
        W3["NTP (123/udp)"]
    end

    subgraph App["App Tier Egress"]
        A1["DB port → DB SG"]
        A2["HTTPS (443/tcp)"]
        A3["DNS (53/tcp+udp)"]
        A4["NTP (123/udp)"]
    end

    subgraph DB["DB Tier Egress"]
        D1["DNS (53/tcp+udp)"]
        D2["NTP (123/udp)"]
    end

    subgraph Bastion["Bastion Tier Egress"]
        B1["SSH (22/tcp) → VPC CIDR"]
        B2["DNS (53/tcp+udp)"]
        B3["NTP (123/udp)"]
    end
```

## Design Decisions

- **Layered access**: Each tier only accepts ingress from the tier above it
- **Bastion off by default**: Must explicitly enable and provide allowed CIDRs
- **Egress**: Unrestricted by default for backwards compatibility; `restrict_egress = true` locks down per tier
- **name_prefix + create_before_destroy**: Prevents downtime during SG replacement
