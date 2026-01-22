/* vms = {
  database = {
    cores      = 2
    memory     = 2048
    disk_size  = 50
    node       = "arcanine"
    ip_address = "192.168.1.160"
  }
}

containers = {
  dev-monitor-01 = {
    cores      = 2
    memory     = 2048
    node       = "arcanine"
    image      = "ubuntu-22.04-standard"
    ip_address = "192.168.1.170"
  }
}

environment = "dev"
template_vm_id = 9000
 */

node                = "arcanine"

## Image Variables
image_filename           = "jammy-server-cloudimg-amd64.img"
image_url                = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"

## VM Variables
vm_id   = 9012
vm_name = "ubuntu-jammy"
bios    = "seabios"
