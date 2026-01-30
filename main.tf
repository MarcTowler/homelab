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