output "vm_ips" {
  description = "IP addresses of created VMs"
  value = {
    for name, vm in proxmox_virtual_environment_vm.this :
    name => try(vm.initialization[0].ip_config[0].ipv4[0].address, "pending")
  }
}