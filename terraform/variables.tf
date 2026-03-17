variable "base_image" {
  description = "Path or URL to the base Debian 13 image"
  type        = string
  default     = "../packer/output/debian13-base.qcow2"
}
