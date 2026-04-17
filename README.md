# Homelab - Infrastructure as Code

Complete infrastructure-as-code for a home lab environment using Terraform and Ansible. Provisions and configures a full monitoring stack (Prometheus + Grafana), containerized services, and supporting infrastructure across multiple Proxmox nodes.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Deployment](#deployment)
- [Service Access](#service-access)
- [Validation & Monitoring](#validation--monitoring)
- [Troubleshooting](#troubleshooting)
- [File Reference](#file-reference)

---

## Quick Start

### Prerequisites
- **Proxmox Cluster:** 3 nodes with internet access (arcanine, growlithe, fuecoco)
- **SSL Certificates:** Domain-validated certs at `ansible/files/`
- **Ansible Vault:** Secrets file at `ansible/inventory/secrets.yml`
- **Terraform:** v1.x with Proxmox provider

### Deployment

```bash
# 1. Update variables for your environment
cp environment/dev.tfvars terraform.tfvars

# 2. Initialize and deploy infrastructure
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 3. Deploy and configure all services (with automatic validation)
cd ansible
ansible-playbook playbooks/site.yml

# 4. Verify everything is healthy
ansible-playbook playbooks/validate.yml
```

### Remote Terraform state (MinIO on Proxmox)

```bash
# 1. Prepare backend config from template (contains MinIO endpoint and keys)
cp backend.hcl.example backend.hcl

# IMPORTANT: endpoint in backend.hcl must be a full URL (for example: http://10.0.1.120:9000)
# For MinIO, keep `skip_requesting_account_id = true` in backend.hcl to avoid STS/IAM account checks.

# 2. Initialize backend (first time)
terraform init -reconfigure -backend-config=backend.hcl

# 3. Migrate existing local state to remote MinIO backend
terraform init -migrate-state -backend-config=backend.hcl
```

`backend.hcl` is git-ignored and must not be committed.

#### MinIO backend bootstrap

```bash
# Configure MinIO on the tfstate backend container
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/minio-tfstate.yml
```

Required Vault secrets in `ansible/inventory/secrets.yml`:

- `minio_root_user`
- `minio_root_password`

### Service Access

After deployment, services are immediately available:

| Service | URL | Credentials | Port |
|---------|-----|-------------|------|
| **Grafana** | http://10.0.1.132:3000 | admin / 690Aburn79! | 3000 |
| **Prometheus** | http://10.0.1.132:9090 | - | 9090 |
| **Homelab Dashboard** | http://10.0.1.132:3000/d/homelab-overview | - | 3000 |

---

## Project Structure

```
homelab/
├── terraform/                    # Infrastructure-as-code (Proxmox resources)
│   ├── main.tf                   # Proxmox provider + container definitions
│   ├── ansible.tf                # Dynamic Ansible inventory generation
│   ├── providers.tf              # Provider configuration
│   ├── variables.tf              # Variable definitions
│   ├── outputs.tf                # Output values
│   ├── containers.tf             # LXC container resources
│   ├── certificates.tf           # SSL certificate configuration
│   └── vm-template.sh            # Container initialization script
│
├── ansible/                      # Configuration management
│   ├── playbooks/
│   │   ├── site.yml              # Master orchestration playbook
│   │   ├── monitoring.yml        # Deploy Prometheus + Grafana (with validators)
│   │   ├── validate.yml          # Health checks (standalone or after deploy)
│   │   ├── php-server.yml        # PHP + Apache configuration
│   │   ├── mysql-server.yml      # MySQL installation + setup
│   │   ├── api.yml               # API service configuration
│   │   ├── gapi.yml              # Game API service configuration
│   │   └── homepage.yml          # Homepage service configuration
│   │
│   ├── roles/
│   │   └── base/                 # Base system setup (users, SSH, firewall)
│   │       └── main.yml
│   │
│   ├── inventory/
│   │   ├── hosts.yml             # Dynamic inventory (auto-generated from Terraform)
│   │   ├── secrets.yml           # Vault secrets (passwords, API keys)
│   │   ├── homepage_data.yml     # Homepage service configuration
│   │   └── group_vars/
│   │       └── all.yml           # Global variables
│   │
│   ├── templates/                # Jinja2 templates for configurations
│   │   ├── prometheus.yml.j2     # Prometheus config with target scrape
│   │   ├── prometheus-alerts.yml.j2
│   │   ├── grafana-datasources.yml.j2
│   │   ├── grafana-dashboards.yml.j2
│   │   ├── homelab-overview-dashboard.json.j2
│   │   ├── prometheus.service.j2
│   │   ├── grafana.service.j2
│   │   ├── node-exporter.service.j2
│   │   ├── mysql-exporter.service.j2
│   │   ├── mysql-exporter.cnf.j2
│   │   ├── apache-api.conf.j2
│   │   ├── apache-gapi.conf.j2
│   │   └── homepage-services.yaml.j2
│   │
│   ├── files/                    # Static files
│   │   ├── api_deploy_key        # API service deployment SSH key
│   │   ├── gapi_deploy_key       # GAPI service deployment SSH key
│   │   └── sql_imports/          # Database initialization SQL files
│   │
│   ├── ansible.cfg               # Ansible configuration
│   └── requirements.yml          # Ansible Galaxy dependencies
│
├── environment/
│   └── dev.tfvars                # Development environment variables
│
├── terraform.tfvars              # Current deployment variables (git ignored)
├── terraform.tfstate             # Current infrastructure state
├── terraform.tfstate.backup      # Previous infrastructure state backup
│
├── MONITORING_QUICK_START.md     # Quick reference for monitoring setup
└── README.md                      # This file
```

---

## Architecture

```
PROXMOX CLUSTER (Physical)
├─ arcanine (10.0.1.150)
│  └─ Node Exporter:9100 → Prometheus
│
├─ growlithe (10.0.1.233)
│  └─ Node Exporter:9100 → Prometheus
│
└─ fuecoco (10.0.1.113)
   └─ Node Exporter:9100 → Prometheus


LXC CONTAINERS (Virtual)
├─ monitoring (10.0.1.132) [4 cores, 4GB RAM]
│  ├─ Prometheus:9090 (TSDB)
│  │  └─ Scrapes targets every 30s
│  │
│  └─ Grafana:3000 (Visualization)
│     ├─ Datasource: Prometheus
│     ├─ Dashboard: Homelab Overview (auto-provisioned)
│     └─ Displays: CPU, Memory, Disk, Network, MySQL metrics
│
├─ db (10.0.1.129) [2 cores, 2GB RAM]
│  ├─ MySQL:3306
│  └─ MySQL Exporter:9104 → Prometheus
│     └─ Metrics: Connections, Query Rate, Threads
│
├─ api (10.0.0.1)
│  ├─ Apache + PHP
│  └─ Node Exporter:9100 → Prometheus
│
├─ gapi (10.0.0.2)
│  ├─ Apache + PHP
│  └─ Node Exporter:9100 → Prometheus
│
├─ homepage (10.0.0.3)
│  ├─ Node.js service
│  └─ Node Exporter:9100 → Prometheus
│
├─ site (10.0.0.4)
│  ├─ Static content
│  └─ Node Exporter:9100 → Prometheus
│
└─ traefik (10.0.0.5)
   ├─ Reverse proxy
   └─ Node Exporter:9100 → Prometheus


METRICS FLOW
Services → Node Exporter:9100 ─┐
                                ├─→ Prometheus:9090 ──→ Grafana:3000 [Dashboard]
MySQL Database → MySQL Exporter:9104 ─┘
```

**Key Points:**
- **10 monitored targets:** 3 Proxmox nodes + 7 containers
- **Metrics scraped:** Every 30 seconds
- **Data retention:** 30 days (configurable in prometheus.yml)
- **Alerting:** AlertManager configured but rules customizable

---

## Deployment

### Step 1: Prepare Environment

```bash
# Copy and customize variables for your environment
cp environment/dev.tfvars terraform.tfvars

# Edit terraform.tfvars with your settings:
# - proxmox_api_token_id / proxmox_api_token_secret
# - Proxmox node names (should match your cluster)
# - Container IP ranges
# - Domain name for certificates
```

### Step 2: Deploy Infrastructure with Terraform

```bash
# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply infrastructure changes
terraform apply tfplan

# Status: All 7 containers + 3 Proxmox nodes in dynamic inventory
```

**What Gets Created:**
- 7 LXC containers with networking
- SSH key provisioning
- AutoFS configuration for certificates
- Ansible dynamic inventory (hosts.yml auto-generated)

### Step 3: Configure Services with Ansible

```bash
cd ansible

# Full deployment with automatic validation
ansible-playbook playbooks/site.yml

# This runs:
# 1. Base system setup
# 2. PHP + Apache servers
# 3. MySQL server + monitoring user
# 4. API service deployment
# 5. GAPI service deployment
# 6. Homepage service deployment
# 7. Monitoring stack (Prometheus + Grafana + exporters)
#    - Handlers validate: Prometheus/Grafana health, port connectivity
# 8. Comprehensive health checks (validate.yml)
```

### Step 4: Post-Deployment

```bash
# Standalone validation (verify all components healthy)
ansible-playbook playbooks/validate.yml

# Outputs:
# ✓ Prometheus: Health + Target count
# ✓ Grafana: Health + Datasource count
# ✓ All 10 exporters: Port health + metrics
```

### Step 5: GitHub Actions Terraform Automation

Terraform automation now runs in two workflows:

1. **Pull Request checks** (`.github/workflows/terraform-pr-check.yml`)
   - Trigger: pull requests targeting `main` that change Terraform/workflow files
   - Runs: `terraform init`, `terraform fmt -check`, `terraform validate`, `terraform plan`
   - Uses `environment/dev.tfvars` as default CI tfvars via `ci.auto.tfvars`
   - Uploads: `tfplan.txt` as a workflow artifact for review context
   - Merge gate: set required status check to `Terraform PR Checks / terraform-check`

2. **Post-merge deploy** (`.github/workflows/terraform-deploy-main.yml`)
   - Trigger: push to `main` (including merged PRs)
   - Runs: `terraform init`, `terraform fmt -check`, `terraform validate`, `terraform plan`, `terraform apply`
   - Uses `environment/dev.tfvars` as default CI tfvars via `ci.auto.tfvars`
   - Applies the exact generated `tfplan` file from the same run

Required repository configuration:
- **Secrets:** `TFSTATE_MINIO_ENDPOINT`, `TFSTATE_MINIO_BUCKET`, `TFSTATE_MINIO_ACCESS_KEY`, `TFSTATE_MINIO_SECRET_KEY`
- **Terraform input secrets:** `TF_VAR_PROXMOX_API_URL`, `TF_VAR_PROXMOX_USER`, `TF_VAR_PROXMOX_API_TOKEN`, `TF_VAR_PROXMOX_PASSWORD`, `TF_VAR_TERRAFORM_PASSWORD`, `TF_VAR_NODE`, `TF_VAR_VM_ID`, `TF_VAR_DOMAIN_NAME`, `TF_VAR_CLOUDFLARE_DNS_TOKEN`, `TF_VAR_ACME_EMAIL`, `TF_VAR_SSH_PUBLIC_KEY`
- **SSH key consistency:** `TF_VAR_SSH_PUBLIC_KEY` must be the canonical public key expected in container initialization so CI and local plans do not drift on `user_account.keys`.
- **Runner labels:** `self-hosted`, `linux`, `docker`, and a scope label (default `homelab`, override with repo variable `TERRAFORM_RUNNER_SCOPE`)
- **Branch protection:** require the PR check above before allowing merges to `main`

Example branch protection setup (requires repo admin + authenticated `gh`):

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/MarcTowler/homelab/branches/main/protection \
  -f required_status_checks.strict=true \
  -f required_status_checks.contexts[]="Terraform PR Checks / terraform-check" \
  -f enforce_admins=true \
  -f required_pull_request_reviews.required_approving_review_count=1 \
  -f required_pull_request_reviews.dismiss_stale_reviews=true \
  -f restrictions=
```

---

## Service Access

### Grafana Dashboard

**URL:** `http://10.0.1.132:3000`  
**Credentials:** `admin` / `690Aburn79!`  
**Dashboard:** Homelab Overview (auto-provisioned)

**Panels Available:**
- CPU Usage (per instance)
- Memory Usage (per instance)
- Disk Usage (per instance)
- Network RX/TX (per instance)
- MySQL Active Connections
- MySQL Query Rate
- Service Health Status (up/down for all 10 targets)

### Prometheus

**URL:** `http://10.0.1.132:9090`  
**Access:** Anonymous (read-only)

**Key Views:**
- **`/targets`** - View all 10 scraped targets (Proxmox nodes + containers)
- **`/graph`** - Query builder for custom metrics
- **`/alerts`** - View alert rules and status

### Direct Service Access

All containers are accessible via SSH from Proxmox nodes:

```bash
# Docker to container (from Proxmox node)
pct exec <container-id> /bin/bash

# SSH to container
ssh user@10.0.x.x (if SSH configured)

# MySQL
mysql -h 10.0.1.129 -u prometheus -p (from any container)
```

---

## Validation & Monitoring

### Automatic Validation (During Deployment)

When `ansible-playbook playbooks/site.yml` runs, validation handlers automatically check:

```yaml
Service Started → Handler Triggered → Health Check
  ✓ Prometheus    → validate prometheus health   → HTTP /-/healthy (5 retries)
  ✓ Grafana       → validate grafana health      → HTTP /api/health (5 retries)
  ✓ Node Exporter → validate node exporter       → Port 9100 connectivity
  ✓ MySQL Exporter→ validate mysql exporter      → Port 9104 connectivity
```

**If any check fails:** Playbook stops immediately with clear error message.

### Standalone Validation

Run health checks independently (useful for troubleshooting):

```bash
# Full validation of all components
ansible-playbook playbooks/validate.yml

# Validate single host (e.g., troubleshooting Node Exporter on api)
ansible-playbook playbooks/validate.yml --limit=api

# Validation output example:
# ✓ Prometheus Health Check PASSED
#   Active Targets: 10
#   Dropped Targets: 0
#
# ✓ Grafana Health Check PASSED
#
# ✓ api: Node Exporter HEALTHY (port 9100 responding)
# ✓ gapi: Node Exporter HEALTHY (port 9100 responding)
# ✓ db: MySQL Exporter HEALTHY
#   - Port 9104 responding
#   - Metrics endpoint available
#   - Database connectivity OK
```

### Manual Health Checks

```bash
# From monitoring container:
curl http://10.0.1.132:9090/-/healthy     # Prometheus
curl http://10.0.1.132:3000/api/health    # Grafana

# From any container:
curl http://10.0.0.1:9100/metrics         # Node Exporter (api)
curl http://10.0.1.129:9104/metrics       # MySQL Exporter (db)
```

---

## Troubleshooting

### Dashboard Shows "No Data"

**Symptom:** Grafana dashboard panels display "No data"

**Solutions:**
1. Check Prometheus targets (http://10.0.1.132:9090/targets)
   - All 10 targets should show "UP" status
   - If any show "DOWN", check exporter connectivity

2. Verify exporters are running:
   ```bash
   ansible-playbook playbooks/validate.yml
   ```

3. Check panel datasource assignment:
   - Dashboard → Edit → Select panel → Inspect
   - Datasource should be "Prometheus" (not "MySQL")

### Prometheus Targets Showing "DOWN"

**Symptom:** http://10.0.1.132:9090/targets shows targets with DOWN status

**Troubleshooting:**

```bash
# Check if exporter is running
ansible-playbook playbooks/validate.yml --limit=<hostname>

# Verify port is open from monitoring container
ansible -i inventory/hosts.yml monitoring -m shell -a "curl http://<host-ip>:9100/metrics"

# Check exporter service status
pct exec <container-id> systemctl status node_exporter

# Restart exporter
pct exec <container-id> systemctl restart node_exporter
```

### Growlithe Node Exporter Failed to Deploy

**Symptom:** Node Exporter on growlithe (10.0.1.233) fails to install

**Root Cause:** growlithe has no internet access (cannot download binary)

**Solution:** Manual transfer via arcanine (see MONITORING_QUICK_START.md)

```bash
# On arcanine (has internet)
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz

# Transfer to growlithe
scp node_exporter-1.7.0.linux-amd64.tar.gz root@growlithe:/tmp/

# Continue with manual installation instructions in MONITORING_QUICK_START.md
```

### MySQL Exporter Not Connecting to Database

**Symptom:** MySQL Exporter port 9104 responds but metrics show connection errors

**Solutions:**

```bash
# Check MySQL monitoring user exists
mysql -h 10.0.1.129 -u root -p -e "SELECT user, host FROM mysql.user WHERE user='prometheus';"

# Test connection with .my.cnf
pct exec db cat /etc/mysql_exporter.cnf

# Check exporter logs
pct exec db journalctl -u mysql_exporter -n 50

# Restart exporter
pct exec db systemctl restart mysql_exporter
```

### Grafana Not Provisioning Dashboard

**Symptom:** Dashboard shows in Grafana but not auto-provisioned

**Check:**

```bash
# Verify dashboard file exists in correct location
pct exec monitoring ls -la /var/lib/grafana/provisioning/dashboards/

# Check dashboards config
pct exec monitoring cat /var/lib/grafana/provisioning/dashboards.yml

# Restart Grafana
pct exec monitoring systemctl restart grafana-server

# Check Grafana logs
pct exec monitoring journalctl -u grafana-server -n 50
```

### Vault Secrets Not Loading

**Symptom:** Ansible playbook fails with "vault not found" or secret values missing

**Solutions:**

```bash
# Check secrets file exists
cat ansible/inventory/secrets.yml

# Verify Ansible vault is configured
cat ansible/ansible.cfg | grep vault

# Run playbook with vault password
ansible-playbook playbooks/monitoring.yml --ask-vault-pass

# Or set vault password file
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_password
ansible-playbook playbooks/monitoring.yml
```

---

## File Reference

### Terraform Files

| File | Purpose |
|------|---------|
| `main.tf` | Proxmox provider setup + LXC container definitions |
| `ansible.tf` | Generate dynamic inventory from Terraform outputs |
| `providers.tf` | Proxmox provider configuration |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Export values (container IPs, etc.) |
| `containers.tf` | Individual container resource definitions |
| `certificates.tf` | SSL certificate configuration |

### Ansible Playbooks

| File | Purpose | Hosts | Handlers |
|------|---------|-------|----------|
| `site.yml` | Master orchestration | all | - |
| `monitoring.yml` | Prometheus, Grafana, exporters | monitoring, all, mysql_servers | validate prometheus/grafana/node/mysql health |
| `validate.yml` | Health check suite | monitoring, all, mysql_servers | - |
| `php-server.yml` | Apache + PHP stack | api, gapi, homepage, site | - |
| `mysql-server.yml` | MySQL database | db | - |
| `api.yml` | API service | api | - |
| `gapi.yml` | Game API service | gapi | - |
| `homepage.yml` | Homepage service | homepage | - |

### Ansible Inventory

| File | Purpose |
|------|---------|
| `hosts.yml` | Dynamic inventory (auto-generated, do not edit) |
| `secrets.yml` | Vault-encrypted secrets (passwords, keys) |
| `homepage_data.yml` | Homepage service configuration |
| `group_vars/all.yml` | Global variables |

### Monitoring Configuration

| File | Purpose |
|------|---------|
| `templates/prometheus.yml.j2` | Prometheus config (targets, scrape intervals) |
| `templates/prometheus-alerts.yml.j2` | Alert rules |
| `templates/grafana-datasources.yml.j2` | Grafana datasource provisioning |
| `templates/grafana-dashboards.yml.j2` | Dashboard provisioning config |
| `templates/homelab-overview-dashboard.json.j2` | Main dashboard template |
| `templates/prometheus.service.j2` | Systemd service for Prometheus |
| `templates/grafana.service.j2` | Systemd service for Grafana |
| `templates/node-exporter.service.j2` | Node Exporter systemd service |
| `templates/mysql-exporter.service.j2` | MySQL Exporter systemd service |

---

## Common Commands

```bash
# View infrastructure plan before applying
terraform plan

# Check all hosts are accessible
ansible all -i ansible/inventory/hosts.yml -m ping

# Run full deployment
ansible-playbook ansible/playbooks/site.yml

# Quick health check
ansible-playbook ansible/playbooks/validate.yml

# Troubleshoot single container
ansible-playbook ansible/playbooks/validate.yml --limit=api

# Check Prometheus targets
curl http://10.0.1.132:9090/api/v1/targets | jq '.data.activeTargets | length'

# Query Prometheus
curl 'http://10.0.1.132:9090/api/v1/query?query=up'

# Access Grafana API
curl http://10.0.1.132:3000/api/health
```

---

## Additional Resources

- **Quick Start Guide:** [MONITORING_QUICK_START.md](MONITORING_QUICK_START.md)
- **Prometheus Docs:** https://prometheus.io/docs/
- **Grafana Docs:** https://grafana.com/docs/
- **Ansible Best Practices:** https://docs.ansible.com/ansible/latest/user_guide/index.html
- **Terraform Proxmox Provider:** https://github.com/Telmate/proxmox-api-go

---

**Last Updated:** March 2026  
**Status:** ✅ Fully Operational (Tier 2 Optimization Complete)
