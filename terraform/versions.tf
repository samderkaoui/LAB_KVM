terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "= 0.9.5" #">= 0.9.0" dans le module
    }
    external = {
      source  = "hashicorp/external"
      version = "= 2.0" # ">= 2.0" dans le module
    }
    # null = {
    #   source  = "hashicorp/null"
    #   version = ">= 3.0"
    # }

    local = {
      source  = "hashicorp/local"
      version = "= 2.7.0" # ">=2.6.0" dans le module
    }
  }
}
