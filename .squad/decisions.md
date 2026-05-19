# Squad Decisions

## Active Decisions

### 2026-05-19 — Fix: Ansible Playbook Runner preflight validation
Summary:
- Update the GitHub Actions preflight host resolution step to avoid false negatives and improve diagnostics.
Decision:
- Replace the fragile host-counting pipeline with a more robust approach: omit `--vault-password-file` for `--list-hosts`, remove stderr suppression, use `tail -n +3` and `grep -E '^\s+\S+'` to count hosts, and show diagnostics on failure.
- Additionally, ensure inventory alignment: either add a `site` group to `ansible/inventory/hosts.yml` or update playbooks to target existing groups; ensure Terraform (if used) writes expected groups before workflow runs.
Rationale:
- Prevents preflight failures caused by parsing differences or hidden stderr output and provides actionable diagnostics when host count is zero.

### Implementation Notes
- See `.squad/decisions/inbox/*` for source diagnostics merged on 2026-05-19.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
