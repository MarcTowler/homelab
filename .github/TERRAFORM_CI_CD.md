# Terraform GitHub Actions Setup

## Overview

This repository includes GitHub Actions workflows for Terraform validation, formatting checks, and drift detection. The workflow runs on your self-hosted GitHub runner to manage your Proxmox infrastructure.

## State File Management

The workflow uses **GitHub Actions Artifacts** to store and retrieve the Terraform state file between runs. This approach:

- ✅ Keeps state synchronized between runs
- ✅ Encrypts state in GitHub (encrypted at rest and in transit)
- ✅ Maintains workflow isolation (only repo members with permissions can access)
- ⚠️ **Important**: The state file contains sensitive information - never commit it to Git

### Initial Setup

1. **Manually push initial state to artifacts** (one-time):
   ```bash
   # Run locally first to generate terraform.tfstate in your repo
   cd /home/marctowler/homelab
   terraform plan
   
   # Then commit the GitHub Actions workflow
   git add .github/workflows/
   git commit -m "Add Terraform CI/CD pipeline"
   git push
   
   # Manually trigger the workflow to establish the first state artifact
   # via GitHub Actions UI or:
   gh workflow run terraform-checks.yml
   ```

2. **Configure GitHub Secrets** in your repository:
   
   Go to: **Settings → Secrets and variables → Actions**
   
   Add the following secrets (copy values from your `terraform.tfvars`):

   | Secret Name | Value | Source |
   |---|---|---|
   | `PROXMOX_API_URL` | `https://10.0.1.110:8006/api2/json` | terraform.tfvars |
   | `PROXMOX_USER` | `root@pam!provider` | terraform.tfvars |
   | `PROXMOX_PASSWORD` | Your Proxmox password | terraform.tfvars |
   | `PROXMOX_API_TOKEN` | `root@pam!provider=...` | terraform.tfvars |
   | `TERRAFORM_USER` | `terraform` | terraform.tfvars |
   | `TERRAFORM_PASSWORD` | Your Terraform user password | terraform.tfvars |
   | `PROXMOX_TLS_INSECURE` | `true` | terraform.tfvars |
   | `CLOUDFLARE_DNS_TOKEN` | Your Cloudflare token | terraform.tfvars |

## Workflow Triggers

The `terraform-checks.yml` workflow runs:

1. **On Push** to `main` or `develop` branches (when `.tf` files change)
2. **On Pull Requests** to `main` or `develop` (automatic review/validation)
3. **Daily at 2 AM UTC** (scheduled drift detection)
4. **Manual** via `workflow_dispatch` (GitHub UI or CLI)

## What the Workflow Does

1. **Checks out** your repository code
2. **Downloads** the previous state artifact (if available)
3. **Validates** Terraform format (`terraform fmt -check`)
4. **Initializes** Terraform with downloaded state
5. **Validates** configuration (`terraform validate`)
6. **Plans** changes and detects drift (`terraform plan`)
7. **Comments** on PRs with the plan output
8. **Uploads** updated state as artifact for next run

## Local Development & State Sync

### Keep Local State in Sync

After the workflow runs, you may want to pull the updated state locally:

```bash
# Download latest state from GitHub Actions artifact
gh run list --limit 1 --status completed --workflow terraform-checks.yml
gh run download <RUN_ID> -n terraform-state

# This downloads terraform.tfstate locally
```

### Push Local Changes via Workflow

1. Make your Terraform changes locally
2. Test with `terraform plan`
3. Commit and push to a feature branch
4. Create a PR to trigger the workflow validation
5. Review the workflow output
6. Merge to `main` or `develop` to apply

## Security Considerations

- **Never commit** `terraform.tfstate` or `terraform.tfvars` to Git
- **GitHub Secrets** are encrypted and only visible to workflow authenticated runs
- **Artifacts** are retained for 30 days and encrypted
- **Self-hosted runner** (`github-runner`) has local network access to Proxmox
- **SSH keys** should be available on the runner (configure in Ansible)

## Troubleshooting

### State File Not Found

If the initial run fails with "state file not found":
- This is expected on the first run
- The workflow will create a new state and upload it as artifact
- Subsequent runs will use the artifact

### Format Check Failures

If `terraform fmt -check` fails:
```bash
# Run locally to fix formatting
terraform fmt -recursive

# Commit and push
git add *.tf
git commit -m "Fix terraform formatting"
git push
```

### Plan Shows Unexpected Changes

Run locally to debug:
```bash
# Download latest state
gh run download <RUN_ID> -n terraform-state

# Run plan locally
terraform init
terraform plan
```

### Secrets Not Working

1. Verify secrets are set in GitHub (Settings → Secrets)
2. Check secret names match exactly (case-sensitive)
3. Re-run workflow: `gh workflow run terraform-checks.yml`

## Next Steps

1. Set up GitHub Secrets (see table above)
2. Push the workflow to your repository
3. Manually trigger first run to establish baseline state
4. Monitor runs in GitHub Actions tab
5. Optionally set up branch protection rules to require workflow approval before merging

## Monitoring & Alerts

To set up notifications:
- GitHub Actions failures notify repo admins by default
- Configure additional notifications in repository settings
- For drift detection alerts, consider adding a Slack/email notification step
