# resource "proxmox_virtual_environment_vm" "this" {
#   for_each = var.vms

#   name      = each.key
#   node_name = each.value.node

#   clone {
#     vm_id = proxmox_virtual_environment_vm.vm_template.id
#   }

#   agent {
#     enabled = true
#   }

#   memory {
#     dedicated = each.value.memory
#   }

#   initialization {
#     dns {
#       servers = ["1.1.1.1"]
#     }
#     ip_config {
#       ipv4 {
#         address = "dhcp"
#       }
#     }
#   }

#   depends_on = [ proxmox_virtual_environment_download_file.image ]
# }