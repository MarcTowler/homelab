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

variable "root" {
  description = "The root username for Proxmox API authentication."
  type        = string
  sensitive   = true
  default     = "root"
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

variable "terraform_user" {
  description = "The username for Terraform operations."
  type        = string
  sensitive   = true
  default     = "terraform"
}

variable "terraform_password" {
  description = "The password for Terraform operations."
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
    lxc_id     = number
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



variable "pve_ssh_key_private" {
  description = "File path to private SSH key for PVE - overrides 'pve_password'"
  type        = string
  sensitive   = true
  default     = null
}

## Common Variables
variable "node" {
  description = "Name of Proxmox node to download image on, e.g. `pve`."
  type        = string
}

## Image Variables
variable "vm_image_filename" {
  description = "Filename, default `null` will extract name from URL."
  type        = string
  default     = null
}

variable "vm_image_url" {
  description = "Image URL."
  type        = string
}

variable "ct_image_filename" {
  description = "Filename, default `null` will extract name from URL."
  type        = string
  default     = null
}

variable "ct_image_url" {
  description = "Image URL."
  type        = string
}

/* variable "image_checksum" {
  description = "Image checksum value."
  type        = string
}

variable "image_checksum_algorithm" {
  description = "Image checksum algorithm."
  type        = string
  default     = "sha256"
} */

## VM Variables
variable "vm_id" {
  description = "ID number for new VM."
  type        = number
}

variable "vm_name" {
  description = "Name, must be alphanumeric (may contain dash: `-`). Defaults to PVE naming, `VM <VM_ID>`."
  type        = string
  default     = null
}

variable "bios" {
  description = "VM bios, setting to `ovmf` will automatically create a EFI disk."
  type        = string
  default     = "seabios"
  validation {
    condition     = contains(["seabios", "ovmf"], var.bios)
    error_message = "Invalid bios setting: ${var.bios}. Valid options: 'seabios' or 'ovmf'."
  }
}

variable "users" {
  description = "List of users to create on the VM."
  type = list(object({
    password    = string
    comment     = optional(string, null)
    groups      = optional(list(string), [])
    email       = optional(string, null)
  }))
  default = []
}

variable "roles" {
  description = "List of roles to create on the Proxmox server."
  type = list(object({
    role_name      = string
    role_id        = string
    comment        = optional(string, null)
    privileges     = list(string)
  }))
  default = []
}