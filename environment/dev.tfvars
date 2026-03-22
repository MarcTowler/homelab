#Node Setup
nodes = {
  arcanine = {
    node_name  = "arcanine"
    ip_address = "10.0.1.110"
  }
  growlithe = {
    node_name  = "growlithe"
    ip_address = "10.0.1.111"
  }
  pawmot = {
    node_name  = "pawmot"
    ip_address = "10.0.1.112"
  }
  fuecoco = {
    node_name  = "fuecoco"
    ip_address = "10.0.1.113"
  }
  murkrow = {
    node_name  = "murkrow"
    ip_address = "10.0.1.114"
  }
}

#Virtual Machines
#  vms = {
#   database = {
#     cores      = 2
#     memory     = 2048
#     disk_size  = 50
#     node       = "arcanine"
#     ip_address = "192.168.1.160"
#   }
# }

#Containers
containers = {
  db = {
    lxc_id     = 1000
    cores      = 2
    memory     = 2048
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    mount_points = [
      {
        volume = "local-lvm"
        size   = "10G"
        path   = "/mnt/volume"
      }
    ]
    tags      = ["database", "ubuntu"]
    exporters = ["node", "mysql"]
  },
  api = {
    lxc_id     = 1001
    cores      = 2
    memory     = 4098
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    tags       = ["php", "ubuntu"]
    exporters  = ["node"]
  },
  gapi = {
    lxc_id     = 1002
    cores      = 2
    memory     = 4098
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    tags       = ["php", "ubuntu"]
    exporters  = ["node"]
  },
  site = {
    lxc_id     = 1003
    cores      = 2
    memory     = 4098
    node       = "growlithe"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    tags       = ["php", "ubuntu"]
    exporters  = ["node"]
  },
  homepage = {
    lxc_id     = 1004
    cores      = 2
    memory     = 2048
    node       = "fuecoco"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    tags       = ["npm", "ubuntu"]
    exporters  = ["node"]
  },
  traefik = {
    lxc_id     = 1005
    cores      = 2
    memory     = 2048
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    tags       = ["traefik", "reverse-proxy", "ubuntu"]
    exporters  = ["node"]
  },
  monitoring = {
    lxc_id     = 1006
    cores      = 4
    memory     = 4096
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    mount_points = [
      {
        volume = "local-lvm"
        size   = "50G"
        path   = "/var/lib/prometheus"
      },
      {
        volume = "local-lvm"
        size   = "20G"
        path   = "/var/lib/grafana"
      }
    ]
    tags      = ["monitoring", "prometheus", "grafana", "ubuntu"]
    exporters = ["node"]
  },  
  game-server = {
    lxc_id     = 1007
    cores      = 8
    memory     = 24576
    disk_size  = 100
    node       = "pawmot"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    features = {
      nesting = true
      keyctl  = true
    }
    tags      = ["game-server", "ubuntu"]
    exporters = ["node"]
  },
  discord-bot = {
    lxc_id       = 1008
    cores        = 2
    memory       = 2048
    node         = "murkrow"
    ip_address   = "dhcp"
    image        = "ubuntu_2204"
    features = {
      nesting = true
      keyctl  = true
    }
    unprivileged = false
    tags         = ["discord-bot", "csharp", "ubuntu"]
    exporters    = ["node"]
  },
  media-arr = {
    lxc_id     = 1009
    cores      = 4
    memory     = 8192
    disk_size  = 50
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    features = {
      nesting = true
      keyctl  = true
    }
    mount_points = [
      {
        volume = "local-lvm"
        size   = "100G"
        path   = "/media"
      }
    ]
    tags      = ["media", "arr-stack", "docker", "ubuntu"]
    exporters = ["node"]
  }
  
  /* ,
  github-runner = {
    lxc_id     = 1010
    cores      = 4
    memory     = 8192
    node       = "growlithe"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    features = {
      nesting = true
      keyctl  = true
    }
    mount_points = [
      {
        volume = "local-lvm"
        size   = "50G"
        path   = "/var/lib/github-runner"
      }
    ]
    tags      = ["github-runner", "ci-cd", "ubuntu"]
    exporters = ["node"]
  },
  github-runner-personal = {
    lxc_id     = 1011
    cores      = 4
    memory     = 8192
    node       = "growlithe"
    ip_address = "dhcp"
    image      = "ubuntu_2204"
    features = {
      nesting = true
      keyctl  = true
    }
    mount_points = [
      {
        volume = "local-lvm"
        size   = "50G"
        path   = "/var/lib/github-runner"
      }
    ]
    tags      = ["github-runner", "ci-cd", "ubuntu"]
    exporters = ["node"]
  } */
}

images = {
  ubuntu_2204 = {
    filename = "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    url      = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  },
  # ubuntu_2504 = {
  #   filename = "ubuntu-25.04-server-cloudimg-amd64.img"
  #   url      = "https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img"
  # },
  # windows_2025 = {
  #   filename = "26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
  #   url      = "https://software-static.download.prss.microsoft.com/dbazure/998969d5-f34g-4e03-ac9d-1f9786c66749/26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
  # }
}

template_vm_id = 9000
domain_name    = "itslit.me.uk"
node           = "arcanine"
acme_email     = "marc@marctowler.co.uk"

## VM Variables
vm_id   = 9000
vm_name = "ubuntu-jammy"
bios    = "seabios"
