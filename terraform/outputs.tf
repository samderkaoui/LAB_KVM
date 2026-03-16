output "vm_name" {
  description = "The name of the created VM"
  value       = libvirt_domain.debian_vm.name
}

output "vm_uuid" {
  description = "The UUID of the created VM"
  value       = libvirt_domain.debian_vm.uuid
}
