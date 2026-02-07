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
  insecure = var.proxmox_tls_insecure
  username = "root@pam"
  password = var.terraform_password
  ssh {
    agent    = true
    username = var.root
    password = var.terraform_password
    #private_key = file(var.pve_ssh_key_private)

    node {
      name    = var.node
      address = "10.0.1.150"
    }
  }
}