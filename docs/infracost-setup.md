# Infracost Setup Guide

This guide explains how to configure the required secrets for the GitHub Actions workflow that runs `tofu plan` and Infracost cost estimation on pull requests.

## Prerequisites

- A GitHub repository with the workflow file at `.github/workflows/tofu-plan.yml`
- An AWS account with credentials for running `tofu plan`
- Access to create GitHub repository secrets

---

## 1. Get a Free Infracost API Key

Infracost offers a free tier for open-source and small teams.

### Option A: Via CLI

```bash
# Install Infracost
brew install infracost

# Authenticate (opens browser)
infracost auth login

# Retrieve your API key
infracost configure get api_key
```

### Option B: Via Website

1. Go to [infracost.io](https://www.infracost.io/)
2. Sign up for a free account
3. Navigate to **Org Settings** > **API Keys**
4. Copy your API key

---

## 2. Create an AWS IAM User for CI

Create a dedicated IAM user with **read-only** permissions for running `tofu plan`. This user does not need write access since the workflow only plans, never applies.

### Recommended IAM Policy

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
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

After creating the user, generate an **Access Key** (Security credentials > Access keys > Create access key).

---

## 3. Add GitHub Repository Secrets

Navigate to your repository: **Settings** > **Secrets and variables** > **Actions** > **New repository secret**

Add the following three secrets:

| Secret Name              | Value                              |
| ------------------------ | ---------------------------------- |
| `AWS_ACCESS_KEY_ID`      | Your AWS IAM user access key ID    |
| `AWS_SECRET_ACCESS_KEY`  | Your AWS IAM user secret key       |
| `INFRACOST_API_KEY`      | Your Infracost API key             |

---

## 4. Verify the Setup

1. Create a branch that modifies any file under `infra/`
2. Open a pull request targeting `main`
3. The workflow should trigger automatically
4. Check the **Actions** tab for workflow progress
5. Two comments should appear on the PR:
   - **OpenTofu Plan Results** — format check, validation, and plan output
   - **Infracost** — monthly cost estimate with breakdown by resource

---

## Troubleshooting

| Issue | Solution |
| --- | --- |
| Workflow doesn't trigger | Ensure the PR modifies files under `infra/` and targets `main` |
| AWS authentication fails | Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets are set correctly |
| Infracost error | Verify `INFRACOST_API_KEY` is set; run `infracost configure get api_key` locally to confirm |
| Plan fails but cost works | Infracost parses HCL directly and doesn't need AWS credentials; plan needs valid credentials |
| Comment not appearing | Check that the workflow has `pull-requests: write` permission |
