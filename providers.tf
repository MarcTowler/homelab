terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.6.2"
    }

    http = {
      source  = "hashicorp/http"
      version = ">= 3.5.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}