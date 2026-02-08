#Node Setup
nodes = {
  arcanine = {
    node_name  = "arcanine"
    ip_address = "10.0.1.150"
  }
  growlithe = {
    node_name  = "growlithe"
    ip_address = "10.0.1.233"
  }
  fuecoco = {
    node_name  = "fuecoco"
    ip_address = "10.0.1.113"
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
#Containers
containers = {
  db = {
    lxc_id     = 1000
    cores      = 2
    memory     = 2048
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu-22.04-standard"
  },
  api = {
    lxc_id     = 1001
    cores      = 2
    memory     = 4098
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu-22.04-standard"
  },
  gapi = {
    lxc_id     = 1002
    cores      = 2
    memory     = 4098
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu-22.04-standard"
  },
  site = {
    lxc_id     = 1003
    cores      = 2
    memory     = 4098
    node       = "arcanine"
    ip_address = "dhcp"
    image      = "ubuntu-22.04-standard"
  },
}

template_vm_id = 9000
domain_name    = "itslit.me.uk"
node           = "arcanine"
acme_email     = "marc@marctowler.co.uk"

## Image Variables
vm_image_filename           = "ubuntu-25.04-server-cloudimg-amd64.img"
vm_image_url                = "https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img"
ct_image_filename           = "rootfs.tar.xz"
ct_image_url                = "https://images.linuxcontainers.org/images/ubuntu/jammy/amd64/default/20260126_07:42/rootfs.tar.xz"

## VM Variables
vm_id   = 9000
vm_name = "ubuntu-jammy"
bios    = "seabios"
