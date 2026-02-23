resource "proxmox_virtual_environment_container" "this" {
  for_each    = var.containers
  description = "${each.key} - Managed by Terraform"

  node_name = each.value.node
  vm_id     = each.value.lxc_id

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
  }

  initialization {
    hostname = "${each.key}"

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.ubuntu_container_key.public_key_openssh),
        file("~/.ssh/id_ed25519.pub")
      ]
      password = random_password.ubuntu_container_password.result
    }

    dns {
      domain  = var.domain_name
      servers = [var.gateway]
    }
  }

  network_interface {
    name = each.value.network
  }

  disk {
    datastore_id = each.value.datastore_id
    size         = each.value.disk_size
  }

  operating_system {
    template_file_id = (each.value.image != "") ? "local:vztmpl/${each.value.image}" : proxmox_virtual_environment_download_file.lxc-image.id
    type = each.value.os_type
  }

  dynamic "mount_point" {
    for_each = each.value.mount_points
    content {
      volume = mount_point.value.volume
      size   = mount_point.value.size
      path   = mount_point.value.path
    }
  }

  lifecycle {
    ignore_changes = [startup]
  }

  wait_for_ip {
    ipv4 = true
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  tags = each.value.tags
}

resource "proxmox_virtual_environment_download_file" "lxc-image" {
  node_name    = var.node
  content_type = "vztmpl"
  datastore_id = "local"
  file_name    = var.ct_image_filename
  url          = var.ct_image_url
  #  checksum           = var.image_checksum
  #  checksum_algorithm = var.image_checksum_algorithm
  overwrite = false
}

resource "random_password" "ubuntu_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}