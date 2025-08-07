variable "docker_network_homelab" {
  description = "Docker network configuration for homelab"
  type = object({
    name    = string
    driver  = string
    options = map(string)
    ipam_config = object({
      subnet  = string
      gateway = string
    })
  })
  default = {
    name   = "homelab"
    driver = "macvlan"
    options = {
      parent = "enpls0f0"
    }
    ipam_config = {
      subnet  = ""
      gateway = ""
    }
  }
}

variable "docker_images" {
  description = "List of Docker images to be built"
  type = list(object({
    name         = string
    tag          = string
    keep_locally = bool
    context      = string
    dockerfile   = optional(string, null)
    remote_repo  = optional(string, null)
    static_ip    = optional(string, null)
  }))
}

variable "docker_containers" {
  description = "List of Docker containers to be created"
  type = list(object({
    name           = string
    image          = string
    restart_policy = optional(string, "always")
    ports          = optional(map(string), {})
    environment    = optional(map(string), {})
    volumes        = optional(list(string), [])
    networks       = optional(list(string), [])
    network_mode  = optional(list(string), null)
    static_ip      = optional(string, null)
  }))
  default = []
}