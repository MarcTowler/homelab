resource "proxmox_virtual_environment_vm" "vm_template" {
  depends_on = [proxmox_virtual_environment_download_file.image]

  node_name = var.node
  vm_id     = var.vm_id
  name      = var.vm_name
  bios      = var.bios
  machine   = "q35"
  started   = false # Don't boot the VM
  template  = true  # Turn the VM into a template

  agent {
    enabled = true
  }

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 1024
    floating  = 1024
  }

  # create an EFI disk when the bios is set to ovmf
  dynamic "efi_disk" {
    for_each = (var.bios == "ovmf" ? [1] : [])
    content {
      datastore_id      = "local-lvm"
      file_format       = "raw"
      type              = "4m"
      pre_enrolled_keys = true
    }
  }

  disk {
    file_id      = proxmox_virtual_environment_download_file.image.id
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 8
    file_format  = "raw"
    cache        = "writeback"
    iothread     = false
    ssd          = false
    discard      = "on"
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = "1"
  }

  # cloud-init config
  initialization {
    interface           = "ide2"
    type                = "nocloud"
    vendor_data_file_id = "local:snippets/vendor-data.yaml"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

resource "proxmox_virtual_environment_file" "vendor_data" {
  node_name    = var.node
  datastore_id = "local"
  content_type = "snippets"

  source_raw {
    file_name = "vendor-data.yaml"
    data      = <<-EOF
      #cloud-config
      users:
        - default
        - name: ubuntu
          groups:
            - sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
      package_update: true
      packages:
        - qemu-guest-agent
        - net-tools
        - curl
      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - echo "done" > /tmp/cloud-config.done
      power_state:
        mode: reboot
        timeout: 30
      EOF
  }

  /* lifecycle {
    prevent_destroy = true
  } */
}


resource "proxmox_virtual_environment_download_file" "image" {
  node_name    = var.node
  content_type = "iso"
  datastore_id = "local"
  file_name    = var.vm_image_filename
  url          = var.vm_image_url
  #  checksum           = var.image_checksum
  #  checksum_algorithm = var.image_checksum_algorithm
  overwrite = false

  /* lifecycle {
    prevent_destroy = true
  } */
}
