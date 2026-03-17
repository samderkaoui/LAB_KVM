data "external" "vm_ip" {
  depends_on = [libvirt_domain.vm]

  program = [
    "bash", "-c",
    "for i in $(seq 1 30); do IP=$(sudo virsh domifaddr ${libvirt_domain.vm.name} 2>/dev/null | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+' | head -1); if [ -n \"$IP\" ]; then printf '{\"ip\":\"%s\"}' \"$IP\"; exit 0; fi; sleep 5; done; printf '{\"ip\":\"\"}'"
  ]
}

locals {
  vm_ip = data.external.vm_ip.result.ip
}

resource "null_resource" "ansible" {
  count = var.playbook != "" ? 1 : 0

  depends_on = [data.external.vm_ip]

  triggers = {
    vm_ip    = local.vm_ip
    playbook = var.playbook
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${local.vm_ip},' -u ${var.ansible_user} --private-key ${var.ssh_private_key} --ssh-extra-args='-o StrictHostKeyChecking=no' -e \"vm_hostname_by_cli=${var.vm_name}\" ${var.playbook}"
  }
}

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
