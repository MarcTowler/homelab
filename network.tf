resource "docker_network" "homelab_network" {
  name   = var.docker_network_homelab.name
  driver = var.docker_network_homelab.driver

  options = {
    parent = var.docker_network_homelab.options.parent
  }

  ipam_config {
    subnet  = var.docker_network_homelab.ipam_config.subnet
    gateway = var.docker_network_homelab.ipam_config.gateway
  }
}