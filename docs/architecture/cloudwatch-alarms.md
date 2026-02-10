# CloudWatch Alarms Architecture

```mermaid
flowchart TB
    subgraph Metrics["Metric Sources"]
        ALB["ALB Metrics<br/>5xx count, unhealthy hosts"]
        APIGW["API Gateway Metrics<br/>5xx, 4xx, p99 latency"]
        subgraph VPCFlow["VPC Flow Logs Pipeline"]
            FlowLogs["VPC Flow Logs<br/>CloudWatch Log Group"]
            MetricFilter["Metric Filter<br/>Pattern: REJECT<br/>Namespace: CustomVPCMetrics"]
        end
    end

    FlowLogs -->|"log stream"| MetricFilter

    subgraph Alarms["CloudWatch Alarms (all optional)"]
        A1["ALB 5xx Alarm"]
        A2["ALB Unhealthy Targets"]
        A3["API GW 5xx Alarm"]
        A4["API GW 4xx Alarm"]
        A5["API GW Latency Alarm"]
        A6["VPC Rejected Packets<br/>CustomVPCMetrics namespace"]
    end

    ALB --> A1
    ALB --> A2
    APIGW --> A3
    APIGW --> A4
    APIGW --> A5
    MetricFilter --> A6

    subgraph Notifications["Notification & Response"]
        SNS["SNS Topic<br/>KMS-encrypted"]
        Lambda["Remediation Lambda<br/>(optional)"]
    end

    A1 & A2 & A3 & A4 & A5 & A6 -->|"alarm_actions"| SNS
    A1 & A2 & A3 & A4 & A5 & A6 -.->|"optional"| Lambda

    SNS --> Email["Email/SMS/Slack"]
```

## Design Decisions

- **All alarms optional**: Each gated by `enable_*` variable
- **Metric filter for VPC Flow Logs**: VPC Flow Logs don't publish native CloudWatch metrics; a `aws_cloudwatch_log_metric_filter` extracts rejected packet counts into a custom namespace (`CustomVPCMetrics`)
- **SNS encrypted**: Topic uses customer-managed KMS key
- **treat_missing_data = notBreaching**: Avoids false alarms when metrics are absent
- **Configurable thresholds**: Period, evaluation periods, and threshold per alarm
- **Lambda remediation**: Optional automatic incident response
