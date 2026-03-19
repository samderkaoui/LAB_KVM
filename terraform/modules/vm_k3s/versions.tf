terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.9.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 1.9"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.6.0"
    }
  }
}
