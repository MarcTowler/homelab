# Media-arr Stack Deployment Guide

Complete media management infrastructure for *arr services including Sonarr, Radarr, Lidarr, Prowlarr, Bazarr, Readarr, qBittorrent, and FlareArr.

## 📋 Quick Start

### Prerequisites
- Proxmox cluster with arcanine node available
- arcanine's 1TB second drive mounted at `/mnt/pve/arcanine-2nd`
- Terraform and Ansible ready
- Existing Traefik reverse proxy deployment

### Deployment Steps

```bash
# 1. Update Terraform variables (already done in dev.tfvars)
# media-arr LXC container (ID: 1009) with 4 cores, 8GB RAM

# 2. Deploy infrastructure
terraform plan -out=tfplan
terraform apply tfplan

# 3. Wait for container to boot (2-3 minutes)
# Monitor container status in Proxmox

# 4. Deploy and configure services
cd ansible
ansible-playbook playbooks/site.yml

# 5. Validate all services are healthy
ansible-playbook playbooks/validate.yml --limit=media-arr

# 6. Access services via Traefik
# https://sonarr.itslit.me.uk (requires authentication)
# https://radarr.itslit.me.uk (requires authentication)
# ... etc for all services
```

## 🏗️ Architecture

```
PROXMOX NODE: arcanine
├── Physical: /mnt/pve/arcanine-2nd (1TB drive)
│
└── LXC Container: media-arr (1009)
    ├── Resources: 4 cores, 8GB RAM, 50GB disk
    ├── Docker Engine + Docker Compose
    │
    ├── Services (all containerized):
    │   ├── Sonarr        → sonarr.itslit.me.uk:8989
    │   ├── Radarr        → radarr.itslit.me.uk:7878
    │   ├── Lidarr        → lidarr.itslit.me.uk:8686
    │   ├── Prowlarr      → prowlarr.itslit.me.uk:9696
    │   ├── Bazarr        → bazarr.itslit.me.uk:6767
    │   ├── Readarr       → readarr.itslit.me.uk:8787
    │   ├── qBittorrent   → qbittorrent.itslit.me.uk:8080
    │   ├── FlareArr      → flarearr.itslit.me.uk:8182
    │   └── Node Exporter → prometheus:9100
    │
    ├── Volumes:
    │   ├── /media        → /mnt/pve/arcanine-2nd (shared library)
    │   ├── /downloads    → /downloads (torrent downloads)
    │   └── /config/*     → Persistent service configs
    │
    └── Networking:
        ├── Docker bridge network (media-network)
        └── Traefik integration with SSL/TLS + basic auth
```

## 📊 Service Details

### TV/Movie/Music Management

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Sonarr** | 8989 | sonarr.itslit.me.uk | TV series automation and management |
| **Radarr** | 7878 | radarr.itslit.me.uk | Movie automation and management |
| **Lidarr** | 8686 | lidarr.itslit.me.uk | Music library management |
| **Bazarr** | 6767 | bazarr.itslit.me.uk | Subtitle downloading and management |
| **Readarr** | 8787 | readarr.itslit.me.uk | Book library management (nightly) |

### System Services

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Prowlarr** | 9696 | prowlarr.itslit.me.uk | Indexer management and discovery |
| **qBittorrent** | 8080 | qbittorrent.itslit.me.uk | Torrent client and download manager |
| **FlareArr** | 8182 | flarearr.itslit.me.uk | CDN/Streaming optimization and metadata |
| **Node Exporter** | 9100 | (internal) | Prometheus metrics collection |

## 🔐 Authentication

All *arr services are protected by basic HTTP authentication through Traefik:

- **Username**: `media-user` (configurable)
- **Password**: Auto-generated secure password
- **Configuration**: Stored in Ansible vault (`ansible/inventory/secrets.yml`)

### Changing Credentials

```bash
# Edit vault secrets
ansible-vault edit ansible/inventory/secrets.yml

# Update media_arr_auth_user and media_arr_auth_password

# Redeploy Traefik
ansible-playbook ansible/playbooks/traefik.yml
```

## 📁 Storage Architecture

### Media Paths

All services share common storage:

```
/media (mounted from /mnt/pve/arcanine-2nd)
├── Movies/
│   └── [Radarr managed]
├── TV/
│   └── [Sonarr managed]
├── Music/
│   └── [Lidarr managed]
├── Books/
│   └── [Readarr managed]
└── Subtitles/
    └── [Bazarr managed]

/downloads
├── Torrent downloads (qBittorrent)
└── Import staging for *arr services

/config
├── sonarr/      → Sonarr configuration
├── radarr/      → Radarr configuration
├── lidarr/      → Lidarr configuration
├── prowlarr/    → Prowlarr configuration
├── bazarr/      → Bazarr configuration
├── readarr/     → Readarr configuration
├── qbittorrent/ → qBittorrent configuration
└── flarearr/    → FlareArr configuration
```

### Adding Storage

To expand media storage:

1. **Add to Proxmox** (on arcanine):
   ```bash
   pct set 1009 -mp1 /mnt/storage:/media-extra
   ```

2. **Bind path in services** (update docker-compose.yml):
   ```yaml
   volumes:
     - /media-extra:/media-extra
   ```

3. **Configure in each service** (Sonarr, Radarr, etc.):
   - Path settings → /media or /media-extra

## 🚀 Initial Configuration

### First-Time Setup

1. **Access Sonarr** → `https://sonarr.itslit.me.uk`
   - Click "Settings"
   - Configure: Indexers, Download Client (qBit), Root Folder (/media/TV)

2. **Access Radarr** → `https://radarr.itslit.me.uk`
   - Settings → Configure: Indexers, Download Client, Root Folder (/media/Movies)

3. **Access Prowlarr** → `https://prowlarr.itslit.me.uk`
   - Add indexers (TPB, Nyaa, etc.)
   - Connect to Sonarr, Radarr, Lidarr

4. **Access qBittorrent** → `https://qbittorrent.itslit.me.uk`
   - Default credentials: `admin:adminPassword`
   - **CHANGE IMMEDIATELY**: Tools → Options → WebUI → Authentication

5. **Connect qBit to *arr services**
   - Sonarr: Settings → Download Clients → Add qBittorrent
   - Radarr: Settings → Download Clients → Add qBittorrent
   - Lidarr: Settings → Download Clients → Add qBittorrent

6. **Configure FlareArr** → `https://flarearr.itslit.me.uk`
   - Cloudflare API Token (from vault)
   - Enable for CDN optimization

## 🛠️ Maintenance

### Checking Service Status

```bash
# Local status (from media-arr container)
docker compose ps

# View service logs
docker compose logs sonarr
docker compose logs radarr
docker compose logs qbittorrent

# Service-specific diagnostics
curl http://localhost:8989/api/v3/system/status  # Sonarr
curl http://localhost:7878/api/v3/system/status  # Radarr
curl http://localhost:8686/api/v1/system/status  # Lidarr
curl http://localhost:9696/api/v1/health         # Prowlarr
curl http://localhost:6767/api/system/status     # Bazarr
curl http://localhost:8787/api/v1/system/status  # Readarr
curl http://localhost:8080/api/v2/app/webapiVersion # qBit
```

### Health Checks

```bash
# Validate entire stack from Ansible
ansible-playbook playbooks/validate.yml --limit=media-arr

# Validate single service
ansible media-arr -m uri -a "url=http://localhost:8989/api/v3/system/status"
```

### Restarts

```bash
# Restart all services
ansible media-arr -m shell -a "docker compose -f /var/lib/media-arr/docker-compose.yml restart"

# Restart single service
ansible media-arr -m shell -a "docker compose -f /var/lib/media-arr/docker-compose.yml restart sonarr"
```

### Backup & Recovery

```bash
# Backup all service configs
ansible media-arr -m shell -a "tar czf /tmp/media-arr-backup.tar.gz /config"

# Download backup
scp root@media-arr:/tmp/media-arr-backup.tar.gz ./

# Restore from backup
scp ./media-arr-backup.tar.gz root@media-arr:/tmp/
ansible media-arr -m shell -a "tar xzf /tmp/media-arr-backup.tar.gz -C /"
```

## 📈 Monitoring

### Prometheus Integration

Media-arr container includes Node Exporter for Prometheus monitoring:

```bash
# View metrics
curl http://10.0.1.201:9100/metrics | head -20

# Prometheus scrape target
# Configured automatically in prometheus.yml
# Targets → http://10.0.1.201:9100
```

### Grafana Dashboards

Existing Homelab Overview dashboard includes media-arr metrics:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check container status
pct status 1009

# View container logs
pct exec 1009 dmesg | tail -20

# Restart container
pct restart 1009
```

### Services Not Responding

```bash
# SSH to container
pct exec 1009 /bin/bash

# Check Docker services
docker compose ps

# View logs
docker compose logs

# Restart services
docker compose restart
```

### Traefik Routing Issues

```bash
# Verify container can reach Traefik
ansible media-arr -m shell -a "curl http://traefik:8080/api/routers"

# Check Traefik configuration
ansible traefik -m shell -a "cat /etc/traefik/dynamic/services.toml | grep media"

# Restart Traefik
ansible traefik -m systemd -a "name=traefik state=restarted"
```

### Disk Space Issues

```bash
# Check container disk usage
pct exec 1009 df -h

# Check /media usage
pct exec 1009 du -sh /media

# Expand volume if needed
pct set 1009 -mp0 100  # Expand main disk to 100G
```

### Docker/Compose Issues

```bash
# Rebuild containers
docker compose down
docker compose up -d

# Force pull latest images
docker compose pull
docker compose up -d --force-recreate

# Check Docker system health
docker system df
docker system prune -a
```

## 📞 Support & Debugging

### Enable Debug Logging

```bash
# In docker-compose.yml, add for any service:
environment:
  - SONARR_DEBUG=true  # or service-specific vars

# Restart services
docker compose restart
```

### Collect Diagnostic Information

```bash
# Create comprehensive debug bundle
ansible media-arr -m shell -a "
  docker compose logs > /tmp/docker-logs.txt
  docker system info > /tmp/docker-info.txt
  docker ps -a > /tmp/docker-ps.txt
  df -h > /tmp/disk-usage.txt
  free -h > /tmp/memory-usage.txt
"

# Download bundle
scp root@media-arr:/tmp/*.txt ./
```

### Performance Tuning

For systems with high I/O:

```yaml
# In docker-compose.yml, add resource limits:
services:
  sonarr:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
```

## 🔄 Updates

### Update All Services

```bash
# Pull latest images
ansible media-arr -m shell -a "
  cd /var/lib/media-arr && docker compose pull
"

# Redeploy
ansible-playbook playbooks/media-arr.yml

# Validate
ansible-playbook playbooks/validate.yml --limit=media-arr
```

### Update Specific Service

```bash
# Sonarr only
ansible media-arr -m shell -a "
  cd /var/lib/media-arr && docker compose pull sonarr && docker compose up -d sonarr
"
```

## 📝 Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| docker-compose.yml | /var/lib/media-arr/ | Service definitions and networking |
| Sonarr config | /config/sonarr/ | TV show management config |
| Radarr config | /config/radarr/ | Movie management config |
| Lidarr config | /config/lidarr/ | Music management config |
| Prowlarr config | /config/prowlarr/ | Indexer configuration |
| qBittorrent config | /config/qbittorrent/ | Torrent client settings |
| Bazarr config | /config/bazarr/ | Subtitle settings |
| Readarr config | /config/readarr/ | Book management config |
| FlareArr config | /config/flarearr/ | CDN optimization config |

## ✅ Verification Checklist

After deployment:

- [ ] Container is running: `pct status 1009`
- [ ] All Docker services healthy: `docker compose ps`
- [ ] Can access Sonarr at http://localhost:8989
- [ ] Can access Radarr at http://localhost:7878
- [ ] Can access Prowlarr at http://localhost:9696
- [ ] Can access qBittorrent at http://localhost:8080
- [ ] Traefik routing works: `curl -u media-user:password https://sonarr.itslit.me.uk`
- [ ] Node Exporter metrics available: `curl http://localhost:9100/metrics`
- [ ] Prometheus scrapes media-arr: Check http://prometheus:9090/targets
- [ ] /media mount is accessible: `ls -la /media`
- [ ] Configuration persisted: `ls -la /config/*`

## 🎯 Next Steps

1. **Configure Indexers**: Add torrent/NZB indexers to Prowlarr
2. **Set Quality Profiles**: Define quality settings in Sonarr/Radarr
3. **Add Root Folders**: Point to /media/TV, /media/Movies, etc.
4. **Connect Download Client**: Link qBittorrent to *arr services
5. **Test Import**: Add test media and watch automatic processing
6. **Configure Notifications**: Email/Discord alerts for new items
7. **Enable Monitoring**: Dashboard in Grafana for long-term tracking

---

**Last Updated:** 2026-03-22  
**Status:** ✅ Ready for Deployment
