terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.91.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.4"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  insecure  = var.proxmox_tls_insecure
  username  = var.proxmox_api_token != null && var.proxmox_api_token != "" ? null : var.proxmox_user
  password  = var.proxmox_api_token != null && var.proxmox_api_token != "" ? null : var.terraform_password
  api_token = var.proxmox_api_token != null && var.proxmox_api_token != "" ? var.proxmox_api_token : null

  ssh {
    agent       = !local.pve_ssh_private_key_exists
    username    = var.root
    password    = local.pve_ssh_private_key_exists ? null : var.terraform_password
    private_key = local.pve_ssh_private_key_exists ? file(pathexpand(local.pve_ssh_private_key_path)) : null

    node {
      name    = var.node
      address = var.nodes[var.node].ip_address
    }
  }
}

provider "proxmox" {
  alias     = "root_pam"
  endpoint  = var.proxmox_api_url
  insecure  = var.proxmox_tls_insecure
  username  = "root@pam"
  password  = var.terraform_password
  api_token = null

  ssh {
    agent       = !local.pve_ssh_private_key_exists
    username    = var.root
    password    = local.pve_ssh_private_key_exists ? null : var.terraform_password
    private_key = local.pve_ssh_private_key_exists ? file(pathexpand(local.pve_ssh_private_key_path)) : null

    node {
      name    = var.node
      address = var.nodes[var.node].ip_address
    }
  }
}
