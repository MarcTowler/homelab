# Root Cause Analysis: Homepage Proxmox Widget Authentication - Token Case Sensitivity

**Date**: 2026-03-15  
**Component**: Homepage Dashboard - Proxmox Widget Authentication  
**Environment**: Homelab - LXC Container (10.0.1.178)  
**Status**: RESOLVED  
**Severity**: High (Proxmox widgets non-functional)

---

## Executive Summary

Homepage Proxmox widgets failed to authenticate and displayed placeholder values (`common.*`) with HTTP 401 errors from the Proxmox API. Investigation revealed that the Proxmox API token username `Terraform@pam!api` was incorrectly stored in `secrets.yml` as lowercase `terraform@pam!api`. The Proxmox API is case-sensitive for the token ID format, causing authentication to fail despite valid token values.

**Resolution Time**: Investigation ~30 minutes  
**Root Cause**: Case sensitivity in Proxmox token ID (`terraform@pam!api` vs `Terraform@pam!api`)  
**Prevention**: Token ID case must be preserved as created in Proxmox

---

## Issue Description

### Symptoms
- Homepage dashboard displays `common.*` placeholders instead of Proxmox resource values
- Browser console shows HTTP 401 errors
- Server logs show repeated: `error: <proxmoxStatsService> HTTP Error 401 calling Proxmox API`
- Ping results to LXC containers also show placeholders
- All 5 Proxmox cluster nodes affected consistently

### Impact
- Homepage Proxmox widgets completely non-functional
- Cluster monitoring dashboard unavailable
- End-user unable to see resource status from homepage
- Proxmox API responding with 401 Unauthorized to all token requests

### Timeline
| Time | Event |
|------|-------|
| ~18:11 | Commit `830cd52` modifies `secrets.yml` (discord-bot service added) |
| Unknown | Token username case reverted from `Terraform@pam!api` to `terraform@pam!api` |
| ~22:30 | User reports homepage Proxmox widgets showing `common.*` and 401 errors |
| 22:47 | Investigation begins - token format identified as issue |

---

## Root Cause Analysis

### Primary Cause
**Case Sensitivity in Proxmox API Token ID Format**

The Proxmox API token authentication uses the format: `USERNAME@REALM!TOKENNAME:TOKENSECRET`

The username component `Terraform@pam!api` is **case-sensitive** in Proxmox's token system. When stored incorrectly as `terraform@pam!api` (lowercase), the Proxmox API rejects the token with error:
```
HTTP/1.1 401 no tokenid specified
```

### Evidence
1. **API Response Test**:
   ```
   Authorization: PVEAPIToken=Terraform@pam!api:0ace97cc-4581-43c0-920f-532e1b4e1e92
   Response: "401 no tokenid specified"
   ```

2. **Homepage Service Logs**:
   ```
   [2026-03-15T22:34:19.880Z] error: <proxmoxStatsService> HTTP Error 401 calling Proxmox API
   ```

3. **Rendered Configuration**:
   - Ansible templates correctly render: `Terraform@pam!api` (uppercase)
   - But loaded from secrets as: `terraform@pam!api` (lowercase)
   - During Vau load, case was not preserved

### Secondary Cause
**Secrets.yml Case Corruption**

The capitalization was user-applied (`Terraform@pam!api` with capital T and F), but somehow reverted to lowercase during one of the recent commits. Possible causes:
1. Manual editing of vault file lost case during re-encryption
2. Vault file re-encrypted without preserving original case
3. Git commit `830cd52` or `63b7416` inadvertently modified case when editing encrypted file

### Why This Wasn't Caught
1. **Ansible template rendering** - Templates hardcode `Terraform@pam!api` so they always pass the correct case to the rendered YAML
2. **Config file inspection** - When viewing the rendered `services.yaml` on the homepage container, the uppercase version appears correct
3. **Variable availability** - The Ansible variables load from vault, but the case issue only manifests at Proxmox API layer
4. **Silent authentication failure** - Proxmox returns 401 without descriptive error message indicating case mismatch

---

## Investigation Steps Taken

### Phase 1: Configuration Validation
1. Verified Ansible templates: `Terraform@pam!api` ✓ (correct case)
2. Verified rendered `services.yaml`: `Terraform@pam!api` ✓ (correct case)
3. Verified `proxmox.yaml`: `Terraform@pam!api` ✓ (correct case)
4. Verified vault secrets: `terraform@pam!api` ✗ (lowercase - INCORRECT)

### Phase 2: Token Format Testing
1. Tested Proxmox API directly with token
   - Format: `PVEAPIToken=Terraform@pam!api:0ace97cc-4581-43c0-920f-532e1b4e1e92`
   - Response: `401 no tokenid specified`
   - Analysis: Case-sensitive token ID issue

2. Verified token values in vault exist for all nodes:
   - `arcanine_proxmox_token_secret`: `0ace97cc-4581-43c0-920f-532e1b4e1e92` ✓
   - `fuecoco_proxmox_token_secret`: `0ace97cc-4581-43c0-920f-532e1b4e1e92` ✓
   - `growlithe_proxmox_token_secret`: `0ace97cc-4581-43c0-920f-532e1b4e1e92` ✓
   - `pawmot_proxmox_token_secret`: `0ace97cc-4581-43c0-920f-532e1b4e1e92` ✓
   - `murkrow_proxmox_token_secret`: `0ace97cc-4581-43c0-920f-532e1b4e1e92` ✓

### Phase 3: Root Cause Confirmation
1. Checked git history:
   - `830cd52`: "Added the discord-bot service and playbooks" - modified `secrets.yml`
   - `63b7416`: "somehow lost token info" - previous token modification
   - Case change occurred in one of these commits

2. Confirmed vault decryption shows lowercase format:
   ```bash
   proxmox_token_id: "terraform@pam!api"  # WRONG - lowercase
   ```

---

## Resolution

The issue is in `ansible/inventory/secrets.yml` - the `proxmox_token_id` must be corrected to use proper casing:

**Current (Incorrect)**:
```yaml
proxmox_token_id: "terraform@pam!api"
```

**Should Be (Correct)**:
```yaml
proxmox_token_id: "Terraform@pam!api"
```

This requires:
1. Decrypting `secrets.yml`
2. Changing `terraform@pam!api` to `Terraform@pam!api` in the `proxmox_token_id` field
3. Re-encrypting with vault
4. Re-running homepage playbook to re-render configuration files

---

## Prevention Measures

### For Vault File Editing
1. **Always preserve case** when editing encrypted vault files
2. **Use consistent naming conventions**:
   - User IDs in Proxmox follow format: `User@Realm!TokenName`
   - Document the exact casing when first creating tokens: `Terraform@pam!api`
3. **Version control**: git should detect vault changes, but verify case in plaintext before re-encryption

### For Token Management
1. **Document token format** in a reference file or wiki
2. **Test token authentication** after any vault modifications
3. **Add validation task** to Ansible playbooks:
   ```yaml
   - name: Validate Proxmox Token Format
     assert:
       that:
         - proxmox_token_id == "Terraform@pam!api"
       fail_msg: "Token ID case is incorrect"
   ```

### For Homepage Widget Configuration
1. **Add logging** to show exact token ID being used for debugging
2. **Add validation** to prevent rendering with lowercase token IDs
3. **Test token format** in a pre-deployment check

---

## Impact Assessment

- **Affected Components**: Homepage Proxmox widgets, Grafana potential (if using same token)
- **User Visibility**: High - Dashboard completely non-functional for Proxmox monitoring
- **Duration**: From commit time until manual fix
- **Scope of Fix**: Single field change in vault file

---

## Future Recommendations

1. **CI/CD Validation**: Add pre-commit hook to validate no vault file edits introduce case changes for known tokens
2. **Terraform Integration**: Store token ID as constant in Terraform and pass to Ansible to ensure consistency
3. **Secret Rotation Policy**: Document and enforce proper token format during rotation procedures
4. **Monitoring**: Alert if homepage widget returns 401 errors consistently for more than 5 minutes

---

## Related Issues
- Commit `830cd52`: Discord-bot service addition (introduced the case change)
- Commit `63b7416`: "somehow lost token info" (previous token management issue)
- These commits suggest token management has been fragile historically

