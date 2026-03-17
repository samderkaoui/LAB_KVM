module "vm_k3s_master" {
  source     = "./modules/vm_k3s"
  vm_name    = "k3s-Master"
  base_image = var.base_image
  memory     = 2048
  vcpu       = 2
}

module "vm_k3s_worker_1" {
  source     = "./modules/vm_k3s"
  vm_name    = "k3s-Worker-1"
  base_image = var.base_image
  memory     = 2048
  vcpu       = 2
}

module "vm_k3s_worker_2" {
  source     = "./modules/vm_k3s"
  vm_name    = "k3s-Worker-2"
  base_image = var.base_image
  memory     = 2048
  vcpu       = 2
}
