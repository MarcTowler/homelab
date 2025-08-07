resource "docker_container" "container" {
  for_each = var.containers

  name    = each.value.name
  image   = each.value.image
  restart = each.value.restart_policy

  network_mode = (each.value.network_mode != null) ? each.value.network_mode : null

  dynamic "networks" {
    for_each = each.value.networks
    content {
      name = networks.value
      ipv4_address = networks.value.ipv4_address
    }
  }

  dynamic "ports" {
    for_each = each.value.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  dynamic "environment" {
    for_each = each.value.environment
    content {
      key   = environment.key
      value = environment.value
    }
  }
}