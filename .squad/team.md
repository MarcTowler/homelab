# Squad Team

> homelab

## Coordinator

| Name | Role | Notes |
|------|------|-------|
| Squad | Coordinator | Routes work, enforces handoffs and reviewer gates. |

## Members

| Name | Role | Charter | Status |
|------|------|---------|--------|
| Infrastructure Architect | Lead | Infrastructure foundation & architectural decisions | Active (Lead) |
| Ansible Orchestrator | Specialist | Configuration management & Ansible automation | Active |
| Media Stack Engineer | Specialist | Media *arr stack & streaming services | Active |
| Monitoring Specialist | Specialist | Observability, metrics, and health checks | Active |
| Service Deployment Engineers | Collective | Application services & PHP apps | Active |
| Security Guardian | Specialist | Security, secrets, and compliance | Active |

## Specializations

### 🏗️ Infrastructure Architect (Lead)
- **Charter:** Own infrastructure foundation, coordinate major changes, provide architectural guidance
- **Focus:** Terraform, Proxmox, networking, SSL/TLS, resource management
- **Files:** `*.tf`, environment configs, cluster management
- **Doc:** `.squad/agents/infrastructure-architect.md`

### 🎭 Ansible Orchestrator
- **Charter:** Master configuration management, optimize Ansible code, ensure automation best practices
- **Focus:** Playbooks, roles, templates, variable management, task optimization
- **Files:** `ansible/playbooks/`, `ansible/roles/`, `ansible/group_vars/`, `ansible/templates/`
- **Doc:** `.squad/agents/ansible-orchestrator.md`

### 📺 Media Stack Engineer
- **Charter:** Own media automation stack, ensure service health, optimize media workflows
- **Focus:** Sonarr, Radarr, Lidarr, Prowlarr, Bazarr, Jellyfin, qBittorrent, FlareSolverr
- **Files:** `ansible/playbooks/media-arr*.yml`, `ansible/group_vars/media-arr.yml`, media templates
- **Doc:** `.squad/agents/media-stack-engineer.md`

### 📊 Monitoring Specialist
- **Charter:** Comprehensive observability, proactive monitoring, performance insights
- **Focus:** Prometheus, Grafana, Node Exporter, MySQL Exporter, dashboards, alerts
- **Files:** `ansible/playbooks/monitoring.yml`, `ansible/playbooks/validate.yml`, exporter configs
- **Doc:** `.squad/agents/monitoring-specialist.md`

### 🚀 Service Deployment Engineers
- **Charter:** Deploy and maintain application services, ensure service reliability
- **Focus:** PHP apps (API/GAPI/Website), GitHub runners, Traefik, MySQL, homepage, game server
- **Files:** `ansible/playbooks/{api,gapi,website,traefik,db,homepage,game-server}.yml`
- **Doc:** `.squad/agents/service-deployment-engineers.md`

### 🔒 Security Guardian
- **Charter:** Protect secrets, harden infrastructure, ensure compliance and security
- **Focus:** Ansible Vault, SSH keys, certificates, access controls, vulnerability management
- **Files:** `ansible/group_vars/secrets.yml`, deploy keys, vault files, security configs
- **Doc:** `.squad/agents/security-guardian.md`

## Project Context

- **Project:** homelab
- **Created:** 2026-03-22
