# ALB Architecture

```mermaid
flowchart LR
    Client(["Client"]) -->|"HTTP :80"| HTTPListener
    Client -->|"HTTPS :443"| HTTPSListener

    subgraph ALB["Application Load Balancer"]
        HTTPListener["HTTP Listener<br/>Port 80"]
        HTTPSListener["HTTPS Listener<br/>Port 443<br/>TLS 1.3 Policy"]
    end

    HTTPListener -->|"301 Redirect<br/>(when cert provided)"| HTTPSListener
    HTTPSListener --> TG

    subgraph TG["Default Target Group<br/>Protocol: var.target_protocol"]
        HC["Health Check<br/>Protocol: var.target_protocol<br/>Path: var.health_check_path<br/>Matcher: var.health_check_matcher"]
        Targets["Targets (ip/instance/lambda)"]
    end

    WAF["WAFv2 Web ACL<br/>(optional)"] -.->|"protects"| ALB
    S3["S3 Access Logs<br/>(optional)"] -.->|"logs"| ALB
```

## Design Decisions

- **TLS 1.3 by default**: Uses `ELBSecurityPolicy-TLS13-1-2-2021-06`
- **HTTP→HTTPS redirect**: Automatic when `certificate_arn` is provided
- **Drop invalid headers**: `drop_invalid_header_fields = true` prevents request smuggling
- **Configurable target protocol**: `target_protocol` variable (HTTP or HTTPS) enables end-to-end encryption when backends support TLS
- **Target type `ip`**: Default supports Fargate and container deployments
- **Deletion protection**: Off by default for dev, enable for production
