locals {
  image_node_matrix = {
    for pair in flatten([
      for node_name in keys(var.nodes) : [
        for image_name, image in var.images : {
          key       = "${node_name}-${image_name}"
          node_name = node_name
          image     = image
        }
      ]
    ]) :
    pair.key => pair
  }

  pve_ssh_private_key_path   = try(trimspace(var.pve_ssh_key_private), "")
  pve_ssh_private_key_exists = local.pve_ssh_private_key_path != "" ? fileexists(pathexpand(local.pve_ssh_private_key_path)) : false

  container_primary_ipv4 = {
    for name, container in proxmox_virtual_environment_container.this :
    name => try(
      container.ipv4[try(var.containers[name].network, "veth0")],
      try(container.ipv4.veth0, try([for ip in values(container.ipv4) : ip if ip != null][0], null))
    )
  }
}
