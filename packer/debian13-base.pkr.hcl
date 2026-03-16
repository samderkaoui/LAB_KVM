packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "ssh_username" {}

variable "ssh_password" {
  sensitive = true
}

variable "iso_checksum" {}

source "qemu" "debian13" {
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
  iso_checksum     = var.iso_checksum
  output_directory = "output"
  disk_size        = "20G"
  format           = "qcow2"
  memory           = 2048
  cpus             = 2
  accelerator      = "kvm"
#  headless         = true   # Pour ne pas avoir de GUI lors du build

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

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent python3 python3-pip",
      "sudo systemctl enable qemu-guest-agent",
      # Clé SSH pour Ansible
      "mkdir -p ~/.ssh",
      "curl -s https://raw.githubusercontent.com/TON_GITHUB/lab/main/ansible/files/id_rsa.pub >> ~/.ssh/authorized_keys",
      "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys",
      # Passwordless sudo pour Ansible
      "echo 'lab ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/lab",
      # Nettoyage
      "sudo apt-get clean",
      "sudo cloud-init clean 2>/dev/null || true"
    ]
  }
}
