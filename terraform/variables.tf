variable "base_image" {
  description = "Path or URL to the base Debian 13 image"
  type        = string
  default     = "../packer/output/debian13-base.qcow2"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "debian-vm"
}

variable "vm_memory" {
  description = "Memory allocated to the VM in MiB"
  type        = number
  default     = 2048
}

variable "vm_vcpu" {
  description = "Number of virtual CPUs for the VM"
  type        = number
  default     = 2
}

variable "vm_network" {
  description = "Network name for the VM"
  type        = string
  default     = "default"
}
