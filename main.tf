#Setup the Clusters
resource "proxmox_virtual_environment_hosts" "nodes" {
  for_each = var.nodes

  node_name = each.value.node_name

  entry {
    address = each.value.ip_address

    hostnames = [
      each.value.node_name,
      "${each.value.node_name}.${var.domain_name}"
    ]
  }

  entry {
    address = "127.0.0.1"

    hostnames = [
      "localhost",
      "localhost.localdomain"
    ]
  }
}

#Set the Node timezones
resource "proxmox_virtual_environment_time" "node_time" {
  for_each = var.nodes

  node_name = each.value.node_name
  time_zone = "UTC"
}