default: help

SHELL := /bin/bash -eu
PACKER_DIR  := packer
TERRAFORM_DIR := terraform
PKRVARS     := local.pkrvars.hcl
PKRFILE     := debian13-base.pkr.hcl
DEBIAN_SHA  := https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS

# Colors
export TERM=xterm-256color
grey   = tput setaf 7; echo $1; tput sgr0;
red    = tput setaf 1; echo $1; tput sgr0;
green  = tput setaf 2; echo $1; tput sgr0;
yellow = tput setaf 3; echo $1; tput sgr0;
blue   = tput setaf 4; echo $1; tput sgr0;
purple = tput setaf 5; echo $1; tput sgr0;
cyan   = tput setaf 6; echo $1; tput sgr0;

help:		## Help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

prerequis:	## Configuring QEMU
	@$(call cyan, "Configuring QEMU")
	sudo sed -i 's/^#\?user = .*/user = "root"/' /etc/libvirt/qemu.conf
	sudo sed -i 's/^#\?group = .*/group = "root"/' /etc/libvirt/qemu.conf
	sudo sed -i 's/^#\?security_driver = .*/security_driver = "none"/' /etc/libvirt/qemu.conf
	sudo systemctl restart libvirtd

vm-ips:		## Show all VMs IP addresses
	@$(call cyan, "VMs IP addresses")
	@for vm in $$(sudo virsh list --name); do \
		echo "$$vm:"; \
		sudo virsh domifaddr $$vm 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "  no IP yet"; \
	done

logs-qemu:	## Show QEMU logs
	@$(call cyan, "Showing QEMU logs")
	sudo cat /var/log/libvirt/qemu/debian-vm.log | tail -50

terraform-init:	## Terraform init
	@$(call purple, "Terraform init")
	cd $(TERRAFORM_DIR) && terraform init

terraform-apply:	## Terraform apply
	@$(call cyan, "Terraform apply")
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

terraform-destroy:	## Terraform destroy
	@$(call red, "Terraform destroy")
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

terraform-fmt:	## Terraform fmt
	@$(call green, "Terraform fmt")
	cd $(TERRAFORM_DIR) && terraform fmt

packer-init:		## Packer init
	@$(call cyan, "Packer init")
	cd $(PACKER_DIR) && packer init .

packer-build:		## Packer build
	@$(call green, "Packer build")
	cd $(PACKER_DIR) && packer build -var-file=$(PKRVARS) $(PKRFILE)

sha256:		## Get Debian netinst SHA256
	@$(call yellow, "Fetching Debian netinst SHA256")
	@curl -s $(DEBIAN_SHA) | grep netinst

packer-destroy:	## Clean packer output
	@$(call red, "Removing packer output")
	rm -rf $(PACKER_DIR)/output
