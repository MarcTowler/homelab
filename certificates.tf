#Set the DNS Plugin
resource "proxmox_virtual_environment_acme_dns_plugin" "cloudflare" {
  api    = "cf"
  plugin = "cloudflare"
  
  data = {
    CF_Token = var.cloudflare_dns_token
  }
}

resource "proxmox_virtual_environment_acme_account" "this" {
  name      = "itslit"
  contact   = var.acme_email
  directory = "https://acme-v02.api.letsencrypt.org/directory"
  tos       = "https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf"
}

resource "proxmox_virtual_environment_acme_certificate" "this" {
  for_each = var.nodes

  node_name = each.value.node_name
  account   = proxmox_virtual_environment_acme_account.this.name
  force     = true

  domains = [
    {
      domain = "${each.value.node_name}.${var.domain_name}"
      plugin = proxmox_virtual_environment_acme_dns_plugin.cloudflare.plugin
    }
  ]

  depends_on = [
    proxmox_virtual_environment_acme_account.this,
    proxmox_virtual_environment_acme_dns_plugin.cloudflare
  ]
}