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
    name = "veth0"
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.lxc-image.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type = "ubuntu"
  }

  mount_point {
    # volume mount, a new volume will be created by PVE
    volume = "local-lvm"
    size   = "10G"
    path   = "/mnt/volume"
  }

  mount_point {
    # volume mount, an existing volume will be mounted
    volume = "local-lvm" #:subvol-disk-${each.value.lxc_id}"
    size   = "10G"
    path   = "/mnt/data"
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

resource "null_resource" "install_ssh" {
  for_each = proxmox_virtual_environment_container.this

  triggers = {
    container_id = each.value.vm_id
  }

  # Wait for container to fully boot
  provisioner "local-exec" {
    command = "sleep 15"
  }

  # Update package manager via SSH to Proxmox host
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no root@${each.value.node_name}.${var.domain_name} 'pct exec ${each.value.vm_id} -- apt-get update'"
  }

  # Install SSH server and client
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no root@${each.value.node_name}.${var.domain_name} 'pct exec ${each.value.vm_id} -- apt-get install -y openssh-server openssh-client'"
  }

  # Ensure SSH service is running
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no root@${each.value.node_name}.${var.domain_name} 'pct exec ${each.value.vm_id} -- systemctl start ssh'"
  }

  depends_on = [proxmox_virtual_environment_container.this]
}