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

# Output the inventory location for manual runs
output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}

output "ansible_command" {
  description = "Command to run Ansible playbooks manually"
  value       = "ansible-playbook -i ${local_file.ansible_inventory.filename} ansible/playbooks/site.yml"
}

output "container_ips" {
  description = "IP addresses of created containers"
  value = {
    for name, container in proxmox_virtual_environment_container.this :
    name => try(container.initialization[0].ip_config[0].ipv4[0].address, "pending")
  }
}