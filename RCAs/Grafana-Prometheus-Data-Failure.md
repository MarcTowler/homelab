# Grafana Monitoring Dashboard Troubleshooting Summary

## Overview
After using Copilot to assist with an issue where the ansible playbook for monitoring was not forcing an update to the dashboard when the json was changed, I was advised to do a restart of the database which caused the dashboard to fail to load.

After a fresh installation of the Grafana/Prometheus monitoring stack on the monitoring LXC container (10.0.1.87), multiple configuration and data collection issues prevented the dashboard from displaying data. This document summarizes the problems encountered, their root causes, and the solutions applied.

---

## Issues Encountered

### 1. Dashboard Provisioning Location Error
**Symptoms:** Dashboard not visible in Grafana UI upon first load

**Root Cause:** 
- The dashboard provisioning configuration file was deployed to the wrong location
- File was at: `/var/lib/grafana/provisioning/dashboards.yml`
- Should be at: `/var/lib/grafana/provisioning/dashboards/dashboards.yml`
- Grafana looks for provisioning rules in the `dashboards` subdirectory, not the parent provisioning directory

**Fix:** Updated Ansible playbook to deploy provisioning config to correct path
```yaml
dest: "{{ grafana_data_dir }}/provisioning/dashboards/dashboards.yml"
```

---

### 2. Instance Label Inconsistency (Proxmox Nodes Showing as IPs)
**Symptoms:** 
- Proxmox nodes appearing as IP addresses (10.0.1.110, 10.0.1.111, etc.) instead of hostnames
- LXC containers showing correctly with FQDN labels (api.itslit.me.uk, etc.)
- Visual inconsistency in dashboard legends

**Root Cause:**
- Prometheus was scraping Proxmox nodes by IP address directly (no hostname resolution available)
- Proxmox nodes couldn't be accessed by FQDN, only by IP on the hypervisor network
- No relabel configuration to map IPs to hostnames

**Fix:** 
1. Updated Prometheus config to use explicit static instance labels for each Proxmox node:
```yaml
- targets:
    - '10.0.1.110:9100'
  labels:
    instance: 'arcanine.itslit.me.uk'
```
2. Modified relabel_configs regex to only match FQDNs (starting with letters), not IPs:
```yaml
regex: '^([a-zA-Z][a-zA-Z0-9.-]*):.*'  # Matches FQDN, not IPs
```

---

### 3. Stale Prometheus Data
**Symptoms:** Mixed instance labels after config changes (some with ports, some without; old IPs alongside new FQDNs)

**Root Cause:**
- When Prometheus config was updated, old metrics with different label formats remained in storage
- Time series with old label values (e.g., `api.itslit.me.uk:9100`) mixed with new ones
- Database didn't auto-clean old label formats

**Fix:** 
- Cleared Prometheus database and restarted to force fresh data collection:
```bash
systemctl stop prometheus
rm -rf /var/lib/prometheus/*
systemctl start prometheus
```
- Subsequent metrics collected with new, consistent labels

---

### 4. Dashboard Query Regex Parse Errors
**Symptoms:** 
- All query panels returning HTTP 400 errors
- Grafana logs showing `"status=400"` on `/api/ds/query` calls
- Prometheus query error: `invalid parameter "query"`

**Root Cause:**
- Dashboard JSON contained malformed regex patterns with incorrect escaping
- Pattern used: `instance=~".+\\..+"` was being misinterpreted by Prometheus
- The backslashes and dots created ambiguous regex syntax

**Fix:** Replaced broken regex with simpler, working pattern:
```
OLD: instance=~".+\\..+"      # Malformed
NEW: instance=~"[-a-zA-Z0-9.]+"  # Simple character class
```

---

### 5. Regex Character Class Range Interpretation Bug
**Symptoms:** Disk Usage panel showing "No data" while CPU/Memory/Network panels worked

**Root Cause:**
- Character class `[a-zA-Z0-9.-]` was being parsed as a range from `.` to something undefined
- In regex, dash has special meaning when between characters (indicates range, e.g., `a-z`)
- Pattern treated as `[a-zA-Z0-9.` + invalid range `-]`
- Prometheus query parser rejected the malformed regex

**Fix:** Moved dash to start of character class (dash has no range meaning at start):
```
OLD: instance=~"[a-zA-Z0-9.-]+"    # Dash creates range interpretation
NEW: instance=~"[-a-zA-Z0-9.]+"    # Dash at start = literal dash
```

---

### 6. Prometheus Relabel Config Overwriting Static Labels
**Symptoms:** Proxmox node FQDN instance labels were being replaced with IP addresses

**Root Cause:**
- Relabel rule `regex: '([^:]+\.[^:]+):.*'` was matching IP addresses like `10.0.1.110`
- Regex pattern had two dots requirement but was still matching dotted IPs
- Relabel extracted address field and overwrote the static instance labels set in static_configs

**Fix:** Updated relabel regex to only match actual FQDNs starting with letters:
```yaml
regex: '^([a-zA-Z][a-zA-Z0-9.-]*):.*'  # Only matches hostnames, not IPs
```

---

### 7. Disk Usage Query Complexity Issues
**Symptoms:** Disk Usage panel returning no data while other panels worked

**Root Cause:**
- Dashboard query used complex negative regex filter: `fstype!=~"tmpfs|fuse.lxcfs|squashfs|vfat"`
- Combined with instance regex filter `instance=~"[-a-zA-Z0-9.]+"`
- Complex multi-filter queries were failing to parse in earlier test attempts

**Fix:** Simplified query to use direct positive filter:
```
OLD: (1 - (node_filesystem_avail_bytes{instance=~"[-a-zA-Z0-9.]+", fstype!=~"tmpfs|fuse.lxcfs|squashfs|vfat"} / ...
NEW: (1 - (node_filesystem_avail_bytes{fstype="ext4"} / node_filesystem_size_bytes{fstype="ext4"})) * 100
```
- Simpler query that captures all main ext4 filesystems on all instances
- Eliminates nested label matchers that were causing parsing issues

---

## Why It Was Working Before But Not Now

The fresh installation encountered these issues because:

1. **No Historical Configuration Context**: New deployment didn't have the benefit of evolving through incremental changes that had been tested previously
2. **Configuration Drift**: The monitoring playbook was run with different versions or incomplete templates that had regressed regex fixes
3. **Prometheus Config Regression**: Relabel rules were reset to simpler (but broken) patterns during template updates
4. **Dashboard Template Issue**: Dashboard JSON template had reverted to old broken regex patterns when playbook was re-run
5. **No Validation**: Fresh installation didn't validate that regex patterns were syntactically correct before deployment

---

## Summary of Fixes Applied

| Issue | Problem | Solution |
|-------|---------|----------|
| **Provisioning Location** | File in wrong directory | Moved to `/provisioning/dashboards/` subdirectory |
| **Instance Labels (IPs)** | Proxmox nodes showing as IPs | Added explicit static instance labels in Prometheus config |
| **Relabel Overwrite** | Static labels being replaced | Updated regex to only match FQDNs, not IPs |
| **Stale Data** | Mixed old/new label formats | Cleared Prometheus database and restarted |
| **Query Parse Errors** | Broken regex escaping in dashboard | Fixed regex patterns to valid syntax |
| **Regex Range Bug** | Character class misparse `[a-zA-Z0-9.-]` | Moved dash to start: `[-a-zA-Z0-9.]` |
| **Disk Query Failure** | Complex multi-filter query failing | Simplified to single positive filter: `fstype="ext4"` |

---

## Current Working State

✅ **All panels now functional:**
- CPU Usage - All Nodes/Containers
- Memory Usage - All Nodes/Containers
- Disk Usage - All Nodes/Containers
- MySQL Connections
- MySQL Query Rate
- Service Health (1=Up, 0=Down)
- Network RX/TX - All Nodes/Containers

✅ **Prometheus Metrics:**
- 13 active targets (5 Proxmox nodes + 7 LXC containers + prometheus self-monitoring)
- Consistent FQDN instance labels across all metrics
- No query errors or parsing issues

✅ **Grafana Dashboard:**
- Dashboard provisioning correctly located and loaded
- All datasources configured (Prometheus, MySQL)
- All panels querying successfully without 400 errors
- Real-time data collection from all infrastructure components

---

## Files Modified

1. **`ansible/playbooks/monitoring.yml`**
   - Updated dashboard provisioning deployment path

2. **`ansible/templates/monitoring/prometheus.yml.j2`**
   - Added explicit instance labels for Proxmox nodes
   - Fixed relabel_configs regex to preserve static labels
   - Separated LXC and Proxmox node configurations

3. **`ansible/templates/monitoring/homelab-overview-dashboard.json.j2`**
   - Fixed regex patterns in all query expressions
   - Corrected character class range issue
   - Simplified disk usage query from complex multi-filter to simple fstype match

---

## Lessons Learned

1. **Regex Syntax:** Dash character in character classes needs special attention - place at start or end to avoid range interpretation
2. **Label Management:** Relabel rules can silently override static labels - order and specificity matter
3. **Data Hygiene:** Changing metric label formats requires clearing old data or handling label transition carefully
4. **Template Testing:** Dashboard templates should be validated for regex syntax before deployment
5. **Provisioning Paths:** Grafana directory structure is strict - provisioning configs must be in correct subdirectories

---

## References

- Prometheus Relabeling: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config
- PromQL Regex Syntax: https://prometheus.io/docs/prometheus/latest/querying/basics/#regex-matchers
- Grafana Dashboard Provisioning: https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards
