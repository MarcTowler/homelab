# resource "proxmox_virtual_environment_user" "this" {
#   for_each = var.users

#   user_id     = each.value.user_id
#   password    = each.value.password
#   comment     = each.value.comment
#   groups      = each.value.groups
#   email       = each.value.email
# }
# resource "proxmox_virtual_environment_user" "terraform" {
#   comment  = "Managed by Terraform"
#   password = var.proxmox_password
#   user_id  = var.proxmox_user
# }