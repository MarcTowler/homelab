docker_network_homelab = {
  name   = "homelab"
  driver = "macvlan"

  options = {
    parent = "enpls0f0"
  }

  ipam_config = {
    subnet  = "192.168.0.0/20"
    gateway = "192.168.1.254"
  }
}

docker_images = [
  {
    name         = "bind9"
    tag          = "latest"
    keep_locally = false
    dockerfile   = "Dockerfile"
  },
  {
    name         = "grafana"
    tag          = "latest"
    keep_locally = true
    remote_repo  = "grafana/grafana"
  },
  {
    name         = "node_exporter"
    tag          = "latest"
    keep_locally = true
    remote_repo  = "quay.io/prometheus/node-exporter"
  },
  {
    name         = "prometheus"
    tag          = "latest"
    keep_locally = true
    remote_repo  = "prom/prometheus"
  }
]