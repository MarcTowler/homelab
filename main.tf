resource "proxmox_virtual_environment_resource_pool" "vm_pool" {
    comment = "Managed by Terraform"
    pool_id = "homelab"
}

resource "proxmox_virtual_environment_network" "vlan100" {
    node        = var.cluster_nodes[0]
    network     = "vlan100"
    type        = "vlan"
    interface   = "vmbr0"
    vlan        = 100
}

# Firewall rules
resource "proxmox_virtual_environment_firewall" "cluster_rules" {
  enabled = true
  in_rule {
    action   = "ACCEPT"
    port     = "22"
    protocol = "tcp"
    comment  = "SSH"
  }
  in_rule {
    action   = "ACCEPT"
    port     = "443"
    protocol = "tcp"
    comment  = "HTTPS"
  }
}

# VM from template - Web Server Example
resource "proxmox_virtual_environment_vm" "web_servers" {
  for_each = {
    web1 = {
      cores     = 2
      memory    = 4096
      node      = var.cluster_nodes[0]
      ip        = "192.168.1.151"
    }
    web2 = {
      cores     = 2
      memory    = 4096
      node      = var.cluster_nodes[1]
      ip        = "192.168.1.152"
    }
  }

  vm_id       = 100 + index(keys(proxmox_virtual_environment_vm.web_servers), each.key)
  name        = "web-${each.key}"
  description = "Web server ${each.key}"
  node_name   = each.value.node
  pool_id     = proxmox_virtual_environment_resource_pool.homelab.pool_id

  clone {
    vm_id = data.proxmox_virtual_environment_vms.templates.vms[0].vm_id
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "192.168.1.254"
      }
    }
    
    user_account {
      username = "ubuntu"
      password = random_password.vm_password.result
      keys     = [file("~/.ssh/id_rsa.pub")]
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent",
      "sudo systemctl start qemu-guest-agent"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = each.value.ip
      timeout     = "5m"
    }
  }

  depends_on = [proxmox_virtual_environment_network.vlan100]
}

# LXC Containers - Docker hosts example
resource "proxmox_virtual_environment_lxc" "docker_hosts" {
  for_each = {
    docker1 = {
      cores     = 4
      memory    = 8192
      node      = var.cluster_nodes[0]
      ip        = "192.168.1.153"
    }
    docker2 = {
      cores     = 4
      memory    = 8192
      node      = var.cluster_nodes[1]
      ip        = "192.168.1.154"
    }
  }

  vm_id      = 200 + index(keys(proxmox_virtual_environment_lxc.docker_hosts), each.key)
  hostname   = "docker-${each.key}"
  node_name  = each.value.node
  pool_id    = proxmox_virtual_environment_resource_pool.homelab.pool_id
  description = "Docker host ${each.key}"

  ostemplate = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

  rootfs {
    storage = "local-lvm"
    size    = 50
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  network_interface {
    name = "eth0"

    ip_configuration {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "192.168.1.254"
      }
    }
  }

  features {
    fuse    = true
    nesting = true
  }
}

# Backup jobs for VMs
resource "proxmox_virtual_environment_vm_backup" "daily_backup" {
  for_each = proxmox_virtual_environment_vm.web_servers

  vm_id  = each.value.vm_id
  schedule = "0 2 * * *"  # 2 AM daily
  storage = "local"
  notes = "Daily backup of ${each.value.name}"
}

# Users and permissions
resource "proxmox_virtual_environment_user" "terraform_user" {
  user_id = "terraform@pam"
  password = random_password.terraform_user.result
  comment = "Terraform automation account"
}

resource "proxmox_virtual_environment_acl" "terraform_permissions" {
  propagate = true
  path      = "/pool/homelab"
  role_id   = "Administrator"
  user_id   = proxmox_virtual_environment_user.terraform_user.user_id
}

# Generate secure password for VMs
resource "random_password" "vm_password" {
  length  = 32
  special = true
}

resource "random_password" "terraform_user" {
  length  = 32
  special = true
}

# Data source for VM templates
data "proxmox_virtual_environment_vms" "templates" {
  filters = {
    name = "ubuntu-22-04-template"
  }
}