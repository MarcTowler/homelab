output "vm_ips" {
  description = "IP addresses of created VMs"
  value = {
    for name, vm in proxmox_virtual_environment_vm.web_servers :
    name => try(vm.initialization[0].ip_config[0].ipv4[0].address, "pending")
  }
}

output "container_ips" {
  description = "IP addresses of created containers"
  value = {
    for name, container in proxmox_virtual_environment_lxc.docker_hosts :
    name => try(container.network_interface[0].ip_configuration[0].ipv4[0].address, "pending")
  }
}

output "terraform_user_id" {
  description = "Terraform service account user ID"
  value       = proxmox_virtual_environment_user.terraform_user.user_id
}

output "resource_pool_id" {
  description = "Homelab resource pool ID"
  value       = proxmox_virtual_environment_resource_pool.vm_pool.pool_id
}