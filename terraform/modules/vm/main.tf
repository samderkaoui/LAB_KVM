resource "libvirt_volume" "disk" {
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

resource "libvirt_domain" "vm" {
  name        = var.vm_name
  type        = "kvm"
  running     = true
  memory      = var.memory
  memory_unit = "MiB"
  vcpu        = var.vcpu

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
            volume = libvirt_volume.disk.name
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
            network = var.network
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
