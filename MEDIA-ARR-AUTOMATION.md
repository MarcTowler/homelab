# Media-arr Service Integration Automation

## Overview

The `media-arr-configure.yml` playbook automates all service integrations for the media stack, eliminating manual configuration through web UIs.

## What Gets Automated

### ✅ Prowlarr Application Sync
- **Sonarr** connected to Prowlarr (TV shows)
- **Radarr** connected to Prowlarr (Movies)
- **Lidarr** connected to Prowlarr (Music)
- Indexers added to Prowlarr automatically sync to all three services

### ✅ Download Client Configuration
- **qBittorrent** configured as download client in:
  - Sonarr (category: `tv`)
  - Radarr (category: `movies`)
  - Lidarr (category: `music`)
- Credentials secured with PBKDF2 hashing + Docker network whitelist
- Credentials stored in Ansible vault

### ✅ Root Folder Configuration
- Sonarr: `/media/tv` (with quality profile)
- Radarr: `/media/movies` (with quality profile)
- Lidarr: `/media/music` (with quality + metadata profiles)
- Proper permissions (uid/gid 1000, mode 0775)

### ✅ FlareSolverr Proxy
- CloudFlare bypass proxy integrated with Prowlarr
- Ready for indexers that require it

### ✅ Security
- qBittorrent password hashed with PBKDF2
- Docker subnet whitelisting (172.18.0.0/16)
- All credentials stored in encrypted Ansible vault

### ⏸️ Jellyfin Plugins (Conditional)
- Playbook includes plugin installation tasks
- **Requires manual step:** Generate API token in Jellyfin web UI
- Once token is in vault, plugins auto-install on playbook run
- Supported plugins: Trakt, TheTVDB, OpenSubtitles, Fanart

## Usage

### Run the Automation

```bash
cd ~/homelab
ansible-playbook ansible/playbooks/media-arr-configure.yml \
  -i ansible/inventory/hosts.yml \
  --vault-password-file=ansible/.vault_pass
```

**The playbook is idempotent** - it checks existing configuration and only makes necessary changes. Safe to run multiple times.

### Playbook Execution Flow

1. **Pre-flight Checks**
   - Waits for all services to be responsive
   - Configures qBittorrent credentials and security

2. **API Key Extraction**
   - Automatically extracts API keys from XML config files
   - Stores in Ansible facts for use in subsequent tasks

3. **Prowlarr Integration**
   - Checks if applications already configured
   - Adds Sonarr, Radarr, Lidarr if not present
   - Configures FlareSolverr proxy

4. **Download Client Setup**
   - Checks if qBittorrent already configured in each service
   - Adds download client configuration with proper categories
   - Uses Docker service names for inter-container communication

5. **Root Folder Creation**
   - Creates media directories with proper ownership
   - Configures root folders in each *arr service
   - Lidarr requires quality and metadata profile IDs (fetched automatically)

6. **Optional: Jellyfin Plugins**
   - Only runs if `jellyfin_api_token` is defined in vault
   - Installs plugins and restarts Jellyfin

7. **Verification**
   - Validates Prowlarr applications are configured
   - Displays configuration summary

### Playbook Output Example

```
PLAY RECAP *********************************************************************
media-arr                  : ok=27   changed=2    unreachable=0    failed=0    skipped=11   rescued=0    ignored=0

Configuration Summary:
✓ API Keys Extracted: 5
✓ Prowlarr Applications: 3 (Sonarr, Radarr, Lidarr)
✓ Download Clients: qBittorrent configured in all services
✓ Root Folders: /media/tv, /media/movies, /media/music
✓ FlareSolverr: Integrated with Prowlarr
```

## Vault Configuration

### Required Vault Variables

Located in `ansible/inventory/secrets.yml`:

```yaml
# Basic auth for Traefik
media_arr_auth_user: "media-user"
media_arr_auth_password: "3uZkmZd1EOP2RX7T"

# qBittorrent credentials
qbittorrent_username: "media-user"
qbittorrent_password: "3uZkmZd1EOP2RX7T"

# Optional: Jellyfin API token (for plugin installation)
# jellyfin_api_token: "your-token-here"
```

### Managing Vault Credentials

```bash
# View vault contents
ansible-vault view --vault-password-file=ansible/.vault_pass ansible/inventory/secrets.yml

# Edit vault
ansible-vault edit --vault-password-file=ansible/.vault_pass ansible/inventory/secrets.yml
```

## Manual Steps Required

### 1. Add Indexers to Prowlarr (Required)

After automation completes, you need to add indexers manually:

1. Visit https://prowlarr.itslit.me.uk
2. Go to Indexers → Add Indexer
3. Add your torrent indexers/trackers (requires site-specific credentials)
4. Prowlarr automatically syncs them to Sonarr, Radarr, and Lidarr

**Why manual?** Indexer credentials are site-specific and cannot be automated.

### 2. Jellyfin Plugin Installation (Optional)

To enable automated Jellyfin plugin installation:

1. Visit https://jellyfin.itslit.me.uk
2. Go to Dashboard → Advanced → API Keys
3. Create new API key named "Ansible Automation"
4. Add to vault:
   ```bash
   ansible-vault edit --vault-password-file=ansible/.vault_pass ansible/inventory/secrets.yml
   ```
5. Add line: `jellyfin_api_token: "your-token-here"`
6. Re-run playbook to install plugins

## Architecture Details

### Service Communication

All services communicate via Docker bridge network using service names:
- Prowlarr → Sonarr: `http://sonarr:8989`
- Prowlarr → Radarr: `http://radarr:7878`
- Prowlarr → Lidarr: `http://lidarr:8686`
- *arr → qBittorrent: `http://qbittorrent:8080`
- Prowlarr → FlareSolverr: `http://flaresolverr:8191`

### qBittorrent Security

The playbook configures qBittorrent with multiple security layers:

1. **Password Hashing**: PBKDF2-SHA512 with 100,000 iterations
2. **Network Whitelist**: Allows Docker subnet (172.18.0.0/16) without auth
3. **Local Auth Disabled**: Services on same container can communicate freely
4. **External Access**: Still requires authentication via Traefik

Configuration is written to `/config/qbittorrent/qBittorrent/qBittorrent.conf`:
```ini
[Preferences]
WebUI\Username=media-user
WebUI\Password_PBKDF2="@ByteArray(...)"
WebUI\LocalHostAuth=false
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\AuthSubnetWhitelist=172.18.0.0/16, 127.0.0.1/32
```

### API Key Management

API keys are automatically extracted from service config files:
- Prowlarr: `/config/prowlarr/config.xml`
- Sonarr: `/config/sonarr/config.xml`
- Radarr: `/config/radarr/config.xml`
- Lidarr: `/config/lidarr/config.xml`
- Bazarr: `/config/bazarr/config/config.ini`

Keys are stored in Ansible facts and used throughout the playbook.

## Verification

### Check Configuration Status

```bash
# Verify Prowlarr applications
curl -s 'https://prowlarr.itslit.me.uk/api/v1/applications' \
  -u "media-user:3uZkmZd1EOP2RX7T" \
  -H 'X-Api-Key: <prowlarr-api-key>'

# Verify Sonarr download clients
curl -s 'https://sonarr.itslit.me.uk/api/v3/downloadclient' \
  -u "media-user:3uZkmZd1EOP2RX7T" \
  -H 'X-Api-Key: <sonarr-api-key>'

# Check root folders
curl -s 'https://sonarr.itslit.me.uk/api/v3/rootfolder' \
  -u "media-user:3uZkmZd1EOP2RX7T" \
  -H 'X-Api-Key: <sonarr-api-key>'
```

### Expected Results

- **Prowlarr Applications**: 3 apps (Sonarr, Radarr, Lidarr)
- **Download Clients**: qBittorrent present in all *arr services
- **Root Folders**: One folder per service (/media/tv, /media/movies, /media/music)
- **FlareSolverr**: One proxy entry in Prowlarr

## Troubleshooting

### Issue: Playbook fails with API errors

**Symptom**: 400/401 errors when configuring services

**Solution**:
1. Verify all services are running: `docker compose ps`
2. Check service logs: `docker compose logs <service>`
3. Ensure API keys are valid (may need to restart services)

### Issue: qBittorrent authentication fails

**Symptom**: Download client test fails with "Authentication Failure"

**Solution**:
1. Check qBittorrent config: `cat /config/qbittorrent/qBittorrent/qBittorrent.conf`
2. Verify password hash is set
3. Restart qBittorrent: `docker compose restart qbittorrent`
4. Re-run playbook

### Issue: Services can't connect to each other

**Symptom**: "Connection refused" errors

**Solution**:
1. Verify Docker network: `docker network inspect media-arr_media-network`
2. Check service names resolve: `docker exec sonarr ping qbittorrent`
3. Ensure all containers are on same network

### Issue: Root folder not writable

**Symptom**: "Folder not writable by user 'abc'" error

**Solution**:
1. Check permissions: `ls -la /media`
2. Fix ownership: `chown -R 1000:1000 /media/tv /media/movies /media/music`
3. Fix permissions: `chmod -R 775 /media/tv /media/movies /media/music`
4. Re-run playbook

## Related Files

- **Playbook**: `ansible/playbooks/media-arr-configure.yml`
- **Docker Compose**: `ansible/files/media-arr-docker-compose.yml`
- **Group Vars**: `ansible/group_vars/media-arr.yml` (includes `jellyfin_plugins` list)
- **Vault Secrets**: `ansible/inventory/secrets.yml`
- **Jellyfin Plan**: `files/jellyfin-automation-plan.md`

## Jellyfin Plugin Management

### Default Plugins (Auto-Installed)
The playbook installs these plugins automatically:

1. **Trakt** - Scrobble watched content to Trakt.tv
2. **TheTVDB** - Metadata provider for TV shows
3. **Open Subtitles** - Download subtitles from OpenSubtitles.org
4. **Fanart** - Enhanced artwork and fanart provider
5. **Playback Reporting** - Track playback statistics and viewing habits

### Adding Custom Plugins

Edit `ansible/group_vars/media-arr.yml`:

```yaml
jellyfin_plugins:
  # ... existing plugins ...
  
  - name: "YourPlugin"
    guid: "plugin-guid-here"
    description: "What this plugin does"
```

Find plugin GUIDs in the [Jellyfin Plugin Repository](https://repo.jellyfin.org/releases/plugin/manifest.json).

### Available Additional Plugins

Uncomment in `group_vars/media-arr.yml` to enable:

| Plugin | GUID | Purpose |
|--------|------|---------|
| Kodi Sync Queue | aff7e100-ef3d-4cdb-b3fb-f5f9bd6ca8d4 | Sync library with Kodi |
| LDAP Authentication | 958aad66-3784-4d2a-b89a-a7b6fab6e25c | Enterprise auth |
| Anime | 0417364b-5a93-4ad0-a1f0-b87569a7cf8c | Enhanced anime metadata |

### How API Token Generation Works

The playbook automatically generates Jellyfin API tokens:

1. Authenticates with `jellyfin_admin_username`/`jellyfin_admin_password` from vault
2. Creates permanent API key named "Ansible-Automation"
3. Retrieves token via `/Auth/Keys` endpoint
4. Uses token for plugin installation
5. Displays token for optional vault storage

**Note**: If `jellyfin_api_token` already exists in vault, token generation is skipped (idempotent behavior).

## Future Enhancements

Potential additions to the automation:

1. ~~**Jellyfin API Token**: Automate token generation~~  ✅ **DONE**
2. ~~**Jellyfin Plugins**: Install plugins via Ansible~~ ✅ **DONE**
3. **Indexer Management**: Automate indexer configuration (requires scraping or API tokens)
4. **Quality Profiles**: Custom quality profile creation
5. **Naming Conventions**: Standardized file naming across services
6. **Notifications**: Discord/Slack webhook configuration
7. **Backup Automation**: Config backup to remote storage
8. **Health Monitoring**: Integration with Prometheus/Grafana

---

**Created:** 2026-03-24
**Updated:** 2026-03-24 (Added Jellyfin automation)
**Status:** ✅ Production Ready - Full Automation
**Maintainer:** Automated via Ansible
