output "vm_k3s_master_name" {
  value = module.vm_k3s_master.vm_name
}

output "vm_k3s_master_ip" {
  value = module.vm_k3s_master.vm_ip
}

output "vm_k3s_worker_1_name" {
  value = module.vm_k3s_worker_1.vm_name
}

output "vm_k3s_worker_1_ip" {
  value = module.vm_k3s_worker_1.vm_ip
}

output "vm_k3s_worker_2_name" {
  value = module.vm_k3s_worker_2.vm_name
}

output "vm_k3s_worker_2_ip" {
  value = module.vm_k3s_worker_2.vm_ip
}
