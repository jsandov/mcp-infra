# CI Setup Guide

This guide explains how to configure the required secrets and authentication for the GitHub Actions workflow that runs `tofu plan`, security scanning, and Infracost cost estimation on pull requests.

## Prerequisites

- A GitHub repository with the workflow file at `.github/workflows/tofu-plan.yml`
- An AWS account with an IAM OIDC provider for GitHub Actions
- Access to create GitHub repository secrets

---

## 1. Configure AWS OIDC Authentication (Recommended)

OIDC eliminates the need for long-lived AWS access keys. GitHub Actions assumes an IAM role directly.

### Create the OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create the IAM Role

Create a role with a trust policy that allows your repository:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:jsandov/cloud-voyager-infra:*"
        }
      }
    }
  ]
}
```

### Recommended IAM Policy

Attach a read-only policy for `tofu plan`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TofuPlanReadOnly",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:Get*",
        "elasticloadbalancing:Describe*",
        "iam:Get*",
        "iam:List*",
        "rds:Describe*",
        "s3:Get*",
        "s3:List*",
        "sts:GetCallerIdentity",
        "logs:Describe*",
        "logs:Get*",
        "dynamodb:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 2. Get a Free Infracost API Key

Infracost offers a free tier for open-source and small teams.

### Option A: Via CLI

```bash
brew install infracost
infracost auth login
infracost configure get api_key
```

### Option B: Via Website

1. Go to [infracost.io](https://www.infracost.io/)
2. Sign up for a free account
3. Navigate to **Org Settings** > **API Keys**
4. Copy your API key

---

## 3. Add GitHub Repository Secrets

Navigate to your repository: **Settings** > **Secrets and variables** > **Actions** > **New repository secret**

| Secret Name        | Value                                    |
| ------------------ | ---------------------------------------- |
| `AWS_ROLE_ARN`     | ARN of the OIDC IAM role (e.g., `arn:aws:iam::123456789012:role/GitHubActionsRole`) |
| `INFRACOST_API_KEY` | Your Infracost API key                  |

---

## 4. Verify the Setup

1. Create a branch that modifies any file under `infra/`
2. Open a pull request targeting `main`
3. The workflow should trigger automatically
4. Check the **Actions** tab for workflow progress
5. Three jobs should run:
   - **OpenTofu Plan** — format check, validation, and plan output as PR comment
   - **Security Scanning** — TFLint, Trivy, and Checkov results
   - **Infracost** — monthly cost estimate with breakdown by resource

---

## Troubleshooting

| Issue | Solution |
| --- | --- |
| Workflow doesn't trigger | Ensure the PR modifies files under `infra/` and targets `main` |
| OIDC authentication fails | Verify the OIDC provider exists, role trust policy matches repo, and `AWS_ROLE_ARN` secret is correct |
| Infracost error | Verify `INFRACOST_API_KEY` is set; run `infracost configure get api_key` locally to confirm |
| Plan fails but cost works | Infracost parses HCL directly and doesn't need AWS credentials; plan needs valid credentials |
| Comment not appearing | Check that the workflow has `pull-requests: write` permission |
| Security scan failures | Scans run with soft-fail; check job logs for details on findings |

---

## Legacy: Access Key Authentication

If you cannot use OIDC, you can fall back to access keys:

1. Create an IAM user with the read-only policy above
2. Generate access keys
3. Add secrets: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
4. Update the workflow to use env vars instead of `configure-aws-credentials`

OIDC is strongly recommended as it eliminates long-lived credentials.
