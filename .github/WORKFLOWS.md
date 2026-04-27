# Homelab CI/CD Workflows

This document explains the key CI/CD workflows used in the homelab repository, with emphasis on recent improvements to Ansible visibility, error handling, and preflight validation.

---

## Overview of Improvements

Recent updates have made Ansible execution more **observable**, **reliable**, and **fail-fast**:

- ✅ **Full Ansible visibility**: Complete task-level execution logs are now captured and displayed
- ✅ **Fail-fast on errors**: Ansible failures now stop the workflow immediately instead of silently continuing
- ✅ **Preflight validation**: Direct playbook runs validate host group membership before execution

---

## Terraform Deploy Main Workflow (`terraform-deploy-main.yml`)

### Purpose
Applies Terraform configuration to deploy and configure infrastructure, then runs Ansible playbooks for post-deployment provisioning and configuration management.

**Triggers:**
- Push to `main` branch with changes to `*.tf` files, `*.tfvars` files, or workflow configuration
- Manual trigger via `workflow_dispatch`

### Key Behavior Changes

#### Ansible is Now Installed Automatically
The workflow now includes an **"Ensure Ansible is available"** step that:
- Checks if `ansible-playbook` and `ansible-galaxy` are already installed
- If missing, installs `ansible-core` (version 2.16+) using Python pip
- Adds the Ansible binary to the workflow's PATH

**Before:** Ansible installation was assumed; failures were cryptic if not present.  
**After:** Installation is automatic and reliable.

#### Full Ansible Output is Captured and Displayed

The workflow captures complete Ansible execution logs using:

1. **Terraform apply logging** (`terraform apply | tee terraform-apply.log`)
   - Pipes output to a log file while displaying in real-time

2. **Ansible segment extraction**
   - Extracts all output from first `PLAY [...]` line through final `PLAY RECAP`
   - Saves to `ansible-apply.log` for visibility

3. **GitHub workflow annotations**
   - Logs are displayed in a collapsible section in the workflow summary
   - Full logs are uploaded as artifacts for later review

**Before:** Only Terraform apply summary was visible; Ansible task-level details were hidden.  
**After:** Every Ansible task, handler, and error is visible in the workflow logs.

#### Ansible Failures Now Fail the Workflow

The workflow runs with strict error handling (`set -o pipefail`), meaning:
- If Ansible fails during `terraform apply`, the exit code is propagated
- The workflow immediately fails and stops processing
- No silent failures or continued execution on error

**Before:** Ansible errors were logged but did not fail the workflow due to `on_failure=continue`.  
**After:** Any Ansible error causes the workflow to fail immediately.

### Environment Requirements

The following secrets and variables must be configured:

**Secrets (required):**
- `TF_VAR_PROXMOX_API_URL` - Proxmox API endpoint
- `TF_VAR_PROXMOX_USER` - Proxmox user account
- `TF_VAR_PROXMOX_API_TOKEN` - Proxmox API token
- `TF_VAR_PROXMOX_PASSWORD` - Proxmox password
- `TF_VAR_TERRAFORM_PASSWORD` - Terraform-specific credentials
- `TF_VAR_NODE` - Proxmox node name
- `TF_VAR_VM_ID` - Base VM ID for resources
- `TF_VAR_DOMAIN_NAME` - Domain for DNS records
- `TF_VAR_CLOUDFLARE_DNS_TOKEN` - Cloudflare API token for DNS
- `TF_VAR_ACME_EMAIL` - Email for ACME certificates
- `TF_VAR_SSH_PUBLIC_KEY` - SSH public key for access
- `ANSIBLE_VAULT_PASSWORD` - Ansible vault password for encrypted files
- `TFSTATE_MINIO_ENDPOINT`, `TFSTATE_MINIO_BUCKET`, `TFSTATE_MINIO_ACCESS_KEY`, `TFSTATE_MINIO_SECRET_KEY` - Terraform state backend

### Workflow Steps (in order)

1. **Checkout** - Retrieves the repository code
2. **Terraform version** - Displays installed Terraform version
3. **Load default tfvars** - Loads CI environment variables from `environment/dev.tfvars`
4. **Create backend config** - Configures MinIO backend for state storage
5. **Terraform init** - Initializes Terraform working directory
6. **Terraform fmt check** - Validates code formatting
7. **Terraform validate** - Validates Terraform configuration syntax
8. **Prepare vault password file** - Creates Ansible vault password file from secret
9. **Ensure Ansible is available** - Installs Ansible if needed
10. **Install Ansible collections** - Installs required collections from `ansible/requirements.yml`
11. **Export Ansible vault password** - Sets environment variable for Ansible vault
12. **Terraform plan** - Plans infrastructure changes
13. **Terraform apply** - Applies changes and runs Ansible provisioning
14. **Extract Ansible recap output** - Extracts Ansible execution logs from apply output
15. **Show Ansible recap output** - Displays extracted logs in workflow summary
16. **Upload apply logs artifact** - Stores logs as artifacts for 7 days
17. **Cleanup** - Removes sensitive files (vault password, SSH keys, logs)

### Troubleshooting

#### "Ansible command not found" error
- **Cause:** Ansible was not pre-installed on the runner and installation failed
- **Solution:** Check the "Ensure Ansible is available" step logs. Verify Python 3 is installed on the runner.

#### "Ansible failed" and workflow failed
- **Cause:** An Ansible task failed during provisioning
- **Solution:** 
  1. Check the Ansible execution logs in the "Show Ansible recap output" section
  2. Look for task-level error messages that identify the failure
  3. If the logs don't have enough detail, check the full `terraform-apply.log` artifact
  4. Verify the target host group exists in `ansible/inventory/hosts.yml`

#### "fatal: [hostname]: UNREACHABLE!" errors
- **Cause:** Ansible cannot reach the target host
- **Solution:**
  1. Verify the host IP address in the generated inventory file
  2. Check network connectivity to the host
  3. Verify SSH keys and credentials are correct
  4. Check firewall rules allow SSH access

#### Vault password errors
- **Cause:** `ANSIBLE_VAULT_PASSWORD` secret is missing or incorrect
- **Solution:** Verify the secret is set in repository settings and matches the vault password used to encrypt files

---

## Ansible Playbook Runner Workflow (`ansible-playbook-runner.yml`)

### Purpose
Allows manual execution of a specific Ansible playbook against the current inventory. Useful for:
- Running ad-hoc configuration changes
- Testing new playbooks before merging to main
- Troubleshooting infrastructure issues

**Triggers:**
- Manual trigger via `workflow_dispatch` (UI input for playbook selection)
- Called by other workflows via `workflow_call` (programmatic playbook execution)

### Usage

#### Via GitHub UI
1. Go to **Actions** → **Ansible Playbook Runner**
2. Click **Run workflow**
3. Enter playbook selector (e.g., `api`, `monitoring`, `site`)
4. Click **Run workflow**

#### Via workflow_call (from another workflow)
```yaml
jobs:
  call-playbook:
    uses: ./.github/workflows/ansible-playbook-runner.yml
    with:
      playbook: api
    secrets:
      ANSIBLE_VAULT_PASSWORD: ${{ secrets.ANSIBLE_VAULT_PASSWORD }}
      ANSIBLE_SSH_PRIVATE_KEY: ${{ secrets.ANSIBLE_SSH_PRIVATE_KEY }}
```

### Key Behavior Changes

#### Preflight Host Validation

The workflow now includes a **"Preflight - Validate host resolution"** step that:
- Parses the selected playbook to identify target host groups
- Queries the inventory to count matching hosts
- **Fails immediately if no hosts are found** for the playbook

This prevents silent failures where a playbook runs on zero hosts due to:
- Outdated inventory
- Incorrect host group name in playbook
- Host group doesn't exist in `ansible/inventory/hosts.yml`

**Before:** Playbooks could run on zero hosts without indication; changes appeared to succeed but didn't apply anywhere.  
**After:** Workflow fails fast with clear guidance on how to fix the issue.

#### Ansible Failures Fail the Workflow

Like the Terraform Deploy workflow, playbook failures are no longer silent:
- If a task fails, the workflow stops immediately
- Error details are visible in the workflow logs
- No partial or inconsistent states

#### Automatic Ansible Installation

The workflow automatically installs Ansible if needed (same as Terraform Deploy workflow).

### Supported Playbooks

The workflow validates playbook names against the allowlist in `ansible/playbooks/`:

Common playbooks:
- `api` - Deploy/configure API service
- `monitoring` - Deploy/configure monitoring stack
- `site` - Full site provisioning playbook
- Others as defined in your `ansible/playbooks/` directory

To see the full list of available playbooks, check the workflow run details or look at filenames in `ansible/playbooks/`.

### Environment Requirements

**Secrets (required):**
- `ANSIBLE_VAULT_PASSWORD` - Ansible vault password

**Secrets (optional):**
- `ANSIBLE_SSH_PRIVATE_KEY` - SSH private key for host access (falls back to runner's `~/.ssh/id_ed25519` if not provided)
- `API_DEPLOY_KEY` - Deploy key for API repository (required for `api` playbook)
- `GAPI_DEPLOY_KEY` - Deploy key for GAPI repository (required for `gapi` playbook)
- `WEBSITE_DEPLOY_KEY` - Deploy key for website repository (required for `website` playbook)

### Workflow Steps (in order)

1. **Checkout** - Retrieves the repository code
2. **Resolve and validate playbook selector** - Validates playbook name and resolves to file path
3. **Prepare vault password file** - Creates Ansible vault password file from secret
4. **Prepare SSH private key** - Sets up SSH authentication for Ansible hosts
5. **Prepare application deploy key files** - Writes deploy keys to `ansible/files/` directory
6. **Show selection** - Displays the selected playbook and resolved inventory
7. **Ensure Ansible is available** - Installs Ansible if needed
8. **Preflight - Validate host resolution** - **Checks that the playbook targets at least one host**
9. **Install Ansible collections** - Installs required collections from `ansible/requirements.yml`
10. **Run selected playbook** - Executes the Ansible playbook
11. **Cleanup vault password file** - Removes vault password file
12. **Cleanup SSH private key file** - Removes SSH key file (if created from secret)

### Troubleshooting

#### "No hosts found for playbook" error
- **Cause:** The playbook targets a host group that doesn't exist in the current inventory, or the inventory is outdated
- **Solution:**
  1. Verify the playbook targets the correct host group in the playbook's `hosts:` directive (e.g., `hosts: api_servers`)
  2. Check that the host group exists in `ansible/inventory/hosts.yml`
  3. If the inventory is outdated, run the **Terraform Deploy Main** workflow to regenerate it from current infrastructure
  4. Verify that at least one host matches the group criteria in `ansible.tf`

#### "Unsupported playbook selector" error
- **Cause:** The provided playbook name doesn't exist or doesn't match the allowlist
- **Solution:**
  1. Check the error message for the list of allowed playbook selectors
  2. Verify the playbook file exists at `ansible/playbooks/{name}.yml`
  3. Use the exact filename without the `.yml` extension

#### "UNREACHABLE" errors during playbook run
- **Cause:** Ansible cannot connect to target hosts
- **Solution:**
  1. Verify hosts are running and have network connectivity
  2. Verify SSH keys are correct and deployed to hosts
  3. Check that hosts allow SSH access (firewall, security groups, etc.)
  4. Run **Terraform Deploy Main** to verify current inventory is correct

#### "Missing deploy key" error
- **Cause:** A required deploy key secret is not set for the selected playbook
- **Solution:**
  1. Identify which deploy key is required (error message indicates `api`, `gapi`, or `website`)
  2. Add the corresponding secret to repository settings:
     - For API: set `API_DEPLOY_KEY`
     - For GAPI: set `GAPI_DEPLOY_KEY`
     - For website: set `WEBSITE_DEPLOY_KEY`
  3. Re-run the workflow

#### "Ansible failed" and workflow failed
- **Cause:** An Ansible task failed during playbook execution
- **Solution:**
  1. Check the "Run selected playbook" step in the workflow logs for error details
  2. Look for the failed task name and error message
  3. Fix the issue (incorrect variables, missing files, host configuration, etc.)
  4. Re-run the workflow

---

## Understanding Ansible Inventory Generation

The Ansible inventory is **automatically generated** from Terraform infrastructure during the **Terraform Deploy Main** workflow via the `ansible.tf` resource.

### Inventory Structure

The generated `ansible/inventory/hosts.yml` contains:

**Service-based groups** (for application deployments):
- `api_servers` - Containers matching "api" in name
- `mysql_servers` - Containers matching "db" in name
- `monitoring` - Containers matching "monitoring" in name
- `traefik` - Containers matching "traefik" in name
- `media-arr` - Containers matching "media-arr" in name
- `fitbit` - Container named exactly "fitbit"
- `github_runners_org` - Containers matching "github-runner-org-"
- `github_runners_personal_homelab` - Containers matching "github-runner-homelab-"
- `github_runners_personal_litbot` - Containers matching "github-runner-litbot-"
- `tfstate_backend` - Container named "tfstate-minio"
- `proxmox_nodes` - Proxmox nodes defined in `var.nodes`

**Exporter-based groups** (for monitoring):
- `node_exporters` - Containers with "node" exporter enabled
- `mysql_exporters` - Containers with "mysql" exporter enabled
- `proxmox_node_exporters` - Proxmox nodes (all have node exporter)

### When to Regenerate

The inventory is **regenerated** whenever:
- `terraform apply` is run (via Terraform Deploy Main workflow)
- Infrastructure changes (new/deleted containers or nodes)
- Exporter configuration changes in `var.containers`

If the inventory is **stale** (doesn't match current infrastructure):
- Playbooks may target zero hosts
- Manual playbook runs will fail preflight validation
- Run **Terraform Deploy Main** to update the inventory

---

## Best Practices

### Workflow Selection

Use **Terraform Deploy Main** when:
- Making infrastructure changes (new containers, new nodes, etc.)
- Applying configuration changes that require Terraform validation
- Deploying new applications or services
- Regenerating the Ansible inventory

Use **Ansible Playbook Runner** when:
- Running ad-hoc configuration changes on existing infrastructure
- Testing playbooks before merging to main
- Troubleshooting specific services or hosts
- Running a subset of provisioning tasks

### Monitoring and Debugging

- **Check workflow logs** - Every step is logged; look for task-level error details
- **Review artifacts** - `terraform-apply.log` and `ansible-apply.log` contain full execution details
- **Verify inventory** - After Terraform Deploy Main, check `ansible/inventory/hosts.yml` to ensure hosts are correct
- **Test playbooks locally** - Run playbooks on your machine before running in the workflow:
  ```bash
  ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/api.yml --vault-password-file ~/.vault_pass
  ```

### Error Handling

- **Fail-fast is intentional** - Workflows stop on errors to prevent partial or inconsistent state
- **Fix and retry** - Address the error cause and re-run the workflow
- **Don't force successes** - Avoid using `ignore_errors` or `continue_on_error` unless explicitly needed; failures usually indicate a real problem

### Security

- **Vault passwords** - Never commit vault password files; always use secrets
- **SSH keys** - Use repository secrets for SSH keys; don't commit private keys
- **Deploy keys** - Store deploy keys as repository secrets; scope them to specific repositories
- **Log retention** - Artifacts are retained for 7 days; sensitive output is cleaned up automatically

---

## Common Workflow Scenarios

### Scenario 1: Deploy a New Container and Configure It

1. Edit `variables.tf` to add new container configuration
2. Commit and push to main
3. **Terraform Deploy Main** workflow runs automatically
   - Terraform creates the container
   - Ansible provisioning runs on all defined playbooks
   - Full execution logs visible in workflow output
4. Check the workflow logs for any errors
5. If successful, the container is deployed and configured

### Scenario 2: Quick Configuration Change Without Infrastructure Changes

1. Update an Ansible playbook (e.g., `ansible/playbooks/api.yml`)
2. Run **Ansible Playbook Runner** workflow, select `api` playbook
3. Preflight check confirms `api_servers` host group exists
4. Playbook runs only on API servers
5. Check logs for task-level execution details

### Scenario 3: Troubleshoot Why Playbook Has No Hosts

1. Run **Ansible Playbook Runner**, get "No hosts matched" error
2. Check the error message; it indicates inventory may be stale
3. Run **Terraform Deploy Main** to regenerate inventory
   - This also ensures infrastructure is up-to-date
4. Re-run **Ansible Playbook Runner** on the desired playbook
5. Should now find hosts and execute successfully

### Scenario 4: Ansible Task Fails Mid-Execution

1. **Terraform Deploy Main** workflow fails at "Terraform apply" step
2. Check the "Show Ansible recap output" section to find failed task
3. Look at task-level error message and fix the issue (e.g., missing file, incorrect variable)
4. Re-run **Terraform Deploy Main** or **Ansible Playbook Runner** with the fix
5. Workflow should now succeed

---

## Workflow Artifacts and Logs

### Available Artifacts

After **Terraform Deploy Main** workflow runs:
- `terraform-apply-logs-{run_number}` - Contains:
  - `terraform-apply.log` - Full Terraform and Ansible execution output
  - `ansible-apply.log` - Extracted Ansible execution segment (plays and tasks)

Artifacts are retained for **7 days** and can be downloaded from the workflow run summary.

### Reading Logs

The `terraform-apply.log` is very large (full execution output). For Ansible issues:
1. First check `ansible-apply.log` - It's filtered to just the Ansible segment
2. Look for lines starting with `TASK [...]` or `fatal: [host]:` for errors
3. If more context needed, check full `terraform-apply.log` around the error lines

---

## Contributing and Modifying Workflows

### Safe Modifications

- Test changes in a branch before merging to main
- Use `workflow_dispatch` to manually trigger workflows during testing
- Run **Ansible Playbook Runner** to test playbooks before deploying

### What NOT to Do

- ❌ Don't remove the `set -o pipefail` error handling (breaks fail-fast behavior)
- ❌ Don't add `continue_on_error` or `ignore_errors` unless essential (breaks error propagation)
- ❌ Don't remove Ansible output capture; it's essential for debugging
- ❌ Don't skip the preflight validation in Ansible Playbook Runner

### When to Update This Document

Update `WORKFLOWS.md` when:
- Adding a new workflow
- Changing workflow behavior or environment requirements
- Adding troubleshooting steps for new error scenarios
- Updating best practices based on operational experience

---

## References

- **Workflow files:** `.github/workflows/`
- **Ansible playbooks:** `ansible/playbooks/`
- **Ansible inventory:** `ansible/inventory/hosts.yml` (generated from `ansible.tf`)
- **Terraform configuration:** `*.tf` files in repository root
- **Ansible configuration:** `ansible.cfg`, `ansible/requirements.yml`

