variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "base_image" {
  description = "Path to the base qcow2 image"
  type        = string
}

variable "memory" {
  description = "Memory in MiB"
  type        = number
  default     = 2048
}

variable "vcpu" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "network" {
  description = "Network name"
  type        = string
  default     = "default"
}
