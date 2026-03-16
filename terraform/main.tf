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

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "file://${abspath(var.base_image)}"
    }
  }
}

resource "libvirt_domain" "debian_vm" {
  name   = var.vm_name
  type   = "kvm"
  memory      = var.vm_memory
  memory_unit = "MiB"
  vcpu        = var.vm_vcpu

  os = {
    type      = "hvm"
    type_arch = "x86_64"
    boot_devices = [
      { dev = "hd" }
    ]
  }

  devices = {
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
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
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = var.vm_network
          }
        }
      }
    ]

    serials = [
      {
        target = {
          port = 0
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
