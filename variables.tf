variable "proxmox_api_url" {
  description = "The URL of the Proxmox API endpoint."
  type        = string
  sensitive   = false
}

variable "proxmox_user" {
  description = "The username for Proxmox API authentication."
  type        = string
  sensitive   = true
}

variable "proxmox_api_token" {
  description = "The API token for Proxmox API authentication."
  type        = string
  sensitive   = true
}

variable "proxmox_password" {
  description = "The password for Proxmox API authentication."
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Disable TLS certificate verification."
  type        = bool
  default     = true
}

variable "cluster_nodes" {
  description = "Proxmox Cluster Node Names"
  type        = list(string)
  default     = ["arcanine", "growlithe", "fuecoco"]
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "gateway" {
  description = "Default network gateway"
  type        = string
  default     = "192.168.1.254"
}

variable "template_vm_id" {
  description = "VM ID of the template to clone from"
  type        = number
  default     = 9000
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
  sensitive   = false
}

variable "vms" {
  description = "VM Specifications to create"
  type = map(object({
    cores      = number
    memory     = number
    disk_size  = number
    node       = string
    clone      = optional(string, "ubuntu-22-04-template")
    ip_address = string
  }))
  default = {}
}

variable "containers" {
  description = "LXC Container Specifications to create"
  type = map(object({
    cores      = number
    memory     = number
    node       = string
    image      = string
    ip_address = string
  }))
  default = {}
}

variable "virtual_environment_node_name" {
  description = "The Proxmox VE node name where resources will be created."
  type        = string
  default     = "arcanine"
}

variable "datastore_id" {
  description = "The Proxmox VE datastore ID to use for VM disks and files."
  type        = string
  default     = "local"
}