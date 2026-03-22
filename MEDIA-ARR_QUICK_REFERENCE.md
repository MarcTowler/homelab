# Media-arr Quick Reference

## ⚡ Quick Commands

```bash
# Deploy infrastructure
cd /home/marctowler/homelab
terraform plan -out=tfplan && terraform apply tfplan

# Deploy services
cd ansible
ansible-playbook playbooks/site.yml

# Validate services
ansible-playbook playbooks/validate.yml --limit=media-arr

# Check service status
ansible media-arr -m shell -a "docker compose ps"

# View logs
ansible media-arr -m shell -a "docker compose logs -f sonarr"

# Restart all services
ansible media-arr -m shell -a "docker compose restart"

# Restart specific service
ansible media-arr -m shell -a "docker compose restart radarr"
```

## 🌐 Service URLs (with authentication)

| Service | URL | Default Port |
|---------|-----|--------------|
| Sonarr | https://sonarr.itslit.me.uk | 8989 |
| Radarr | https://radarr.itslit.me.uk | 7878 |
| Lidarr | https://lidarr.itslit.me.uk | 8686 |
| Prowlarr | https://prowlarr.itslit.me.uk | 9696 |
| Bazarr | https://bazarr.itslit.me.uk | 6767 |
| Readarr | https://readarr.itslit.me.uk | 8787 |
| qBittorrent | https://qbittorrent.itslit.me.uk | 8080 |
| FlareArr | https://flarearr.itslit.me.uk | 8182 |

**Local Access** (from media-arr container):
- http://localhost:8989 (Sonarr)
- http://localhost:7878 (Radarr)
- etc.

## 📂 Key Paths

```
/media              → Shared media library (from /mnt/pve/arcanine-2nd)
/downloads          → Torrent downloads and staging
/config/sonarr      → Sonarr configuration
/config/radarr      → Radarr configuration
/config/lidarr      → Lidarr configuration
/config/prowlarr    → Prowlarr configuration
/config/bazarr      → Bazarr configuration
/config/readarr     → Readarr configuration
/config/qbittorrent → qBittorrent configuration
/config/flarearr    → FlareArr configuration
```

## 🔧 Configuration Checklist

- [ ] Container deployed (check: `pct status 1009`)
- [ ] All Docker services running (`docker compose ps`)
- [ ] Services accessible via Traefik
- [ ] Prowlarr indexers configured
- [ ] qBittorrent credentials changed (admin/adminPassword)
- [ ] *arr services connected to qBittorrent
- [ ] Root folders configured (/media/TV, /media/Movies, etc.)
- [ ] Test import working
- [ ] Notifications configured
- [ ] Prometheus scraping media-arr metrics

## 🆘 Troubleshooting

```bash
# Container won't start
pct status 1009
pct exec 1009 dmesg | tail -20
pct restart 1009

# Services not running
pct exec 1009 docker compose ps
pct exec 1009 docker compose logs

# Traefik routing not working
ansible traefik -m systemd -a "name=traefik state=restarted"

# Out of disk space
pct exec 1009 df -h
pct exec 1009 du -sh /media

# Metrics not in Prometheus
# Check: http://prometheus:9090/targets for media-arr endpoint
```

## 📚 Full Documentation

See `MEDIA-ARR_DEPLOYMENT.md` for comprehensive guide including:
- Detailed architecture
- Service setup instructions
- Troubleshooting guide
- Backup/recovery procedures
- Performance tuning
- Update procedures

---

**Last Updated:** 2026-03-22  
**Implementation Status:** ✅ Complete
