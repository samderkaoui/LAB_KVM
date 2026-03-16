terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.9.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "debian13_base" {
  name = "${var.vm_name}-base.qcow2"
  pool = "default"

  create = {
    content = {
      url = var.base_image
    }
  }
}

resource "libvirt_domain" "debian_vm" {
  name   = var.vm_name
  type   = "kvm"
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  os = {
    type      = "hvm"
    type_arch = "x86_64"
  }

  devices = {
    disks = [
      {
        target = {
          dev = "vda"
          bus = "virtio"
        }
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.debian13_base.name
          }
        }
      }
    ]

    interfaces = [
      {
        source = {
          network = {
            network = var.vm_network
          }
        }
        wait_for_ip = {
          timeout = 300
        }
      }
    ]

    consoles = [
      {
        target = {
          type = "serial"
          port = 0
        }
      }
    ]
  }
}
