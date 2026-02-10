# CloudWatch Alarms Module PRD

[Back to Overview](README.md)

## Purpose

Provide centralized monitoring and alerting for infrastructure components via CloudWatch alarms and SNS notifications.

## Requirements

### SNS Topic

- Central SNS topic for alarm notifications
- Configurable email/endpoint subscriptions
- KMS encryption on the topic

### ALB Alarms

- HTTP 5xx error rate threshold
- Target response time threshold
- Unhealthy host count threshold
- Configurable evaluation periods and thresholds

### API Gateway Alarms

- 4xx and 5xx error rate thresholds
- Latency (p99) threshold
- Integration error threshold

### VPC Flow Log Alarms

- Rejected traffic spike detection
- Metric filters on flow log group
- Alarm on unusual reject patterns

### Outputs

- SNS topic ARN
- Alarm ARNs (per alarm)
- Dashboard URL (if applicable)

## Security Controls

| Control | Description | Implementation |
| --- | --- | --- |
| SI-4 | System monitoring | CloudWatch alarms on key infrastructure metrics |
| SI-5 | Security alerts | SNS notifications on threshold breaches |
| IR-4 | Incident handling | Automated alerting enables rapid response |
| AU-6 | Audit review | Alarms surface anomalies for investigation |

## Status

**In Progress** -- module design underway; not yet implemented.

## Related Issues

- #31 — CloudWatch alarms module
