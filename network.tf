resource "docker_network" "homelab_network" {
  name = "homelab"
  driver = "macvlan"

  options = {
    parent = "enpls0f0"
  }

  ipam_config {
    subnet = "192.168.0.0/20"
    gateway = "192.168.1.254"
  }
}