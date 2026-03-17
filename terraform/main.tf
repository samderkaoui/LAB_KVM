module "vm_k3s_master" {
  source     = "./modules/vm_k3s"
  vm_name    = "k3s-Master"
  base_image = var.base_image
  memory     = 2048
  vcpu       = 2
  # Old way
  # playbook        = "../ansible/set_hostname.yml"
  # ansible_user    = "lab"
  # ssh_private_key = "../packer/default_id_ed25519"
}

module "vm_k3s_worker_1" {
  source     = "./modules/vm_k3s"
  vm_name    = "k3s-Worker-1"
  base_image = var.base_image
  memory     = 2048
  vcpu       = 2
  # Old way
  # playbook        = "../ansible/set_hostname.yml"
  # ansible_user    = "lab"
  # ssh_private_key = "../packer/default_id_ed25519"
}

module "vm_k3s_worker_2" {
  source     = "./modules/vm_k3s"
  vm_name    = "k3s-Worker-2"
  base_image = var.base_image
  memory     = 2048
  vcpu       = 2
  # Old way
  # playbook        = "../ansible/set_hostname.yml"
  # ansible_user    = "lab"
  # ssh_private_key = "../packer/default_id_ed25519"
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/hosts.yml"
  content  = <<-EOF
    all:
      # commenté car surchargé dans makefile donc pas necessité ici
      # vars:
      #   ansible_user: lab
      #   ansible_ssh_private_key_file: ../packer/default_id_ed25519
      children:
        masters:
          hosts:
            k3s-master:
              ansible_host: ${module.vm_k3s_master.vm_ip}
        workers:
          hosts:
            k3s-worker-1:
              ansible_host: ${module.vm_k3s_worker_1.vm_ip}
            k3s-worker-2:
              ansible_host: ${module.vm_k3s_worker_2.vm_ip}
  EOF
}
