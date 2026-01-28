# output "vm_ips" {
#   description = "IP addresses of created VMs"
#   value = {
#     for name, vm in proxmox_virtual_environment_vm.this :
#     name => try(vm.initialization[0].ip_config[0].ipv4[0].address, "pending")
#   }
# }

output "ubuntu_container_password" {
  value     = random_password.ubuntu_container_password.result
  sensitive = true
}

output "ubuntu_container_private_key" {
  value     = tls_private_key.ubuntu_container_key.private_key_pem
  sensitive = true
}

output "ubuntu_container_public_key" {
  value = tls_private_key.ubuntu_container_key.public_key_openssh
}