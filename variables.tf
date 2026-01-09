variable "proxmox_api_url" {
  description = "The URL of the Proxmox API endpoint."
  type        = string
}

variable "proxmox_user" {
  description = "The username for Proxmox API authentication."
  type        = string
}

variable "proxmox_password" {
  description = "The password for Proxmox API authentication."
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Disable TLS certificate verification."
  type        = bool
  default     = false
}

variable "cluster_nodes" {
    description = "Proxmox Cluster Node Names"
    type        = list(string)
    default     = ["arcanine", "growlithe", "fuecoco"]
}

variable "vms" {
    description = "VM Specifications to create"
    type        = map(object({
        node           = string
        vmid           = number
        name           = string
        cores          = number
        memory         = number
        disk_size      = number
        iso_image      = string
        network_bridge = string
        clone          = optional(string)
        ip_address     = string
    }))
    default = {}
}

variable "containers" {
    description = "LXC Container Specifications to create"
    type        = map(object({
        node           = string
        vmid           = number
        name           = string
        cores          = number
        memory         = number
        disk_size      = number
        template       = string
        network_bridge = string
        ip_address     = string
    }))
    default = {}
}