#Setup the Clusters
resource "proxmox_virtual_environment_hosts" "nodes" {
  for_each = var.nodes

  node_name = each.value.node_name

  entry {
    address = "127.0.0.1"

    hostnames = [
      "localhost",
      "localhost.localdomain"
    ]
  }

  dynamic "entry" {
    for_each = var.nodes
    content {
      address = entry.value.ip_address
      hostnames = [
        entry.value.node_name,
        "${entry.value.node_name}.${var.domain_name}"
      ]
    }
  }
}

#Set the Node timezones
resource "proxmox_virtual_environment_time" "node_time" {
  for_each = var.nodes

  node_name = each.value.node_name
  time_zone = "UTC"
}

#Set the Node DNS
resource "proxmox_virtual_environment_dns" "node_dns" {
  for_each = var.nodes

  node_name = each.value.node_name
  servers = [
    var.gateway,
    "8.8.8.8",
    "1.1.1.1"
  ]
  domain = var.domain_name
}