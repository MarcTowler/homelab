resource "docker_container" "container" {
  for_each = var.containers

  name    = each.value.name
  image   = each.value.image
  restart = each.value.restart_policy
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