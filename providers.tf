terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.91.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure = var.proxmox_tls_insecure
  ssh {
    agent = true
    username = var.terraform_user
    #password = var.terraform_password
    private_key = file(var.pve_ssh_key_private)

    node {
      name = var.node
      address = "192.168.1.150"
    }
  }
}