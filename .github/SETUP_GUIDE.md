# GitHub Actions Setup Checklist

## Quick Setup (5-10 minutes)

### Step 1: Add GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add each of these:

**Required Secrets** (from your `terraform.tfvars`):
```
PROXMOX_API_URL = https://10.0.1.110:8006/api2/json
PROXMOX_USER = root@pam!provider
PROXMOX_PASSWORD = [your password from terraform.tfvars]
PROXMOX_API_TOKEN = root@pam!provider=4c4b6b6d-1222-4019-88b4-92988afdf070
TERRAFORM_USER = terraform
TERRAFORM_PASSWORD = 690Aburn79!
PROXMOX_TLS_INSECURE = true
CLOUDFLARE_DNS_TOKEN = owgXuDJa6r7HU2Vb6ukkJWKpbb4w7OWHqhi6gSB_
```

### Step 2: Commit and Push Workflow

```bash
cd /home/marctowler/homelab
git add .github/workflows/terraform-checks.yml .github/TERRAFORM_CI_CD.md
git commit -m "feat: add Terraform CI/CD pipeline"
git push origin main
```

### Step 3: Make Script Executable

```bash
chmod +x scripts/sync-terraform-state.sh
git add scripts/sync-terraform-state.sh
git commit -m "chore: add terraform state sync helper script"
git push
```

### Step 4: Verify Setup

1. Go to **Actions** tab in GitHub
2. Click **Terraform Validation & Drift Detection**
3. Click **Run workflow** → **Run workflow**
4. Wait 2-3 minutes for completion
5. Check the logs - should show "Using downloaded state file" or "No previous state found"

---

## Configuration Details

### What Each Secret Does

| Secret | Purpose | Security Note |
|--------|---------|---|
| `PROXMOX_*` | Authenticates to your Proxmox API | Needed for all Terraform operations |
| `TERRAFORM_USER/PASSWORD` | SSH access to Proxmox nodes | Used for remote provisioning |
| `CLOUDFLARE_DNS_TOKEN` | Updates DNS records | Scoped to specific domain |

### GitHub Runner Configuration

The workflow uses your self-hosted runner:
- **Label**: `self-hosted, linux`
- **Location**: 10.0.1.182 (github-runner)
- **Network**: Already on your internal network with Proxmox access

**Verify runner is online:**
```bash
# From your machine
ssh root@10.0.1.182 systemctl status github-runner
# Or check GitHub Settings → Actions → Runners
```

---

## Using the Helper Script

### Download Latest State

```bash
./scripts/sync-terraform-state.sh pull
# Output: ✓ State file updated successfully
```

### Backup State Before Changes

```bash
./scripts/sync-terraform-state.sh backup
# Output: ✓ State backed up to: .state-backups/terraform.tfstate.20260309_143022.backup
```

### Check Status

```bash
./scripts/sync-terraform-state.sh status
# Shows state info & recent workflow runs
```

---

## Workflow in Your Development Loop

### Creating New Infrastructure

```bash
# 1. Create a feature branch
git checkout -b feature/add-monitoring-vm

# 2. Write new .tf files
cat > monitoring-vm.tf << 'EOF'
resource "proxmox_virtual_environment_vm" "monitoring" {
  # ... your config
}
EOF

# 3. Test locally
terraform init
terraform plan

# 4. Commit and push
git add monitoring-vm.tf
git commit -m "feat: add new monitoring VM"
git push origin feature/add-monitoring-vm

# 5. Create a PR - workflow auto-validates
# - GitHub Actions runs terraform validate, fmt check, and plan
# - Review the plan in the PR comments
# - Terraform shows exactly what will be created

# 6. Merge to main
# Next: consider setting up auto-apply on merge (optional)
```

### Detecting Infrastructure Drift

**Manual check** (any time):
```bash
./scripts/sync-terraform-state.sh status
# Shows latest workflow run details
```

**Automatic check** (daily):
- Workflow runs every day at 2 AM UTC
- Detects any changes made outside Terraform
- You'll see it in GitHub Actions history

---

## Troubleshooting

### "Error: state file not found"
- This happens on first run - it's normal
- Workflow will create a new state and upload it
- Next runs will use the artifact

### Workflow fails with auth errors
- Verify all secrets are set correctly in GitHub
- Double-check secret names (case-sensitive)
- Test credentials locally:
  ```bash
  terraform plan  # Should work locally with your terraform.tfvars
  ```

### Can't download state with helper script
- Ensure `gh` CLI is installed: `brew install gh` or `apt install gh`
- Authenticate: `gh auth login`
- Check latest run: `gh run list --workflow terraform-checks.yml`

### State conflicts between local and GitHub
- Always run `./scripts/sync-terraform-state.sh pull` before local changes
- Use feature branches with PRs so workflow validates before merging
- Conflicts should be rare with this setup

---

## Security Best Practices

✅ **DO:**
- Keep `terraform.tfvars` in `.gitignore` (never commit)
- Rotate secrets regularly (monthly recommended)
- Use branch protection rules (require workflow approval)
- Review terraform plan in PRs before merging
- Audit workflow runs in GitHub Actions tab

❌ **DON'T:**
- Commit `terraform.tfstate` to Git
- Share GitHub secrets
- Run `terraform apply` locally against production without PR review
- Disable TLS verification in production (only needed for self-signed certs)

---

## Next Steps (Optional)

### Add Auto-Apply Workflow
- Creates a separate workflow that automatically applies changes on merge to main
- Requires additional configuration and safeguards

### Add Slack Notifications
- Posts workflow results to Slack channel
- Useful for team monitoring

### Add Cost Estimation
- Integrates Infracost to show Terraform cost changes
- Attach cost estimates to PR comments

### Set Up Terraform Cloud
- Would replace state artifacts with remote backend
- Recommended for production environments

---

## Need Help?

Check the logs:
1. Go to **Actions** → **Terraform Validation & Drift Detection**
2. Click the failing run
3. Expand the job step that failed
4. Scroll through logs for error messages

Or run locally to debug:
```bash
terraform init
terraform validate
terraform plan
```
