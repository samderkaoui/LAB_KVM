### PLUGINS ###
packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

### VARIABLES ### A laisser pour déclarer la variables car PKVARS fournis seulement la valeur.
variable "ssh_username" {}

variable "ssh_password" {
  sensitive = true
}

variable "iso_checksum" {}

### VM ###
source "qemu" "debian13" {
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
  iso_checksum     = var.iso_checksum
  output_directory = "output"
  disk_size        = "80G"
  format           = "qcow2"
  memory           = 8192
  cpus             = 8
  accelerator      = "kvm"
  disk_interface    = "virtio"
  net_device        = "virtio-net"
  headless         = true   # Pour ne pas avoir de GUI lors du build

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg", {
      username = var.ssh_username
      password = var.ssh_password
    })
  }
  boot_command = [
    "<tab>",
    " auto=true priority=critical url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    "<enter><wait>"
  ]

  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "30m"
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  vm_name          = "debian13-base.qcow2"
}

build {
  sources = ["source.qemu.debian13"]

  provisioner "ansible" {
    playbook_file = "${path.root}/../ansible/base_packer.yml"
    user          = var.ssh_username
    extra_arguments = [
      "--extra-vars", "ansible_become_pass=${var.ssh_password}",
      "--become"
    ]
  }
}
