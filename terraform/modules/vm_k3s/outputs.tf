output "vm_name" {
  value = libvirt_domain.vm.name
}

output "vm_ip" {
  value = local.vm_ip
}
