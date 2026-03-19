.PHONY: help prerequis vm-ips logs-qemu terraform-fmt terraform-validate terraform-init terraform-apply terraform-destroy packer-init packer-build sha256 packer-destroy ansible
# .PHONY` dit à Make que ces cibles **ne sont pas des fichiers**.
default: help

SHELL := /bin/bash -eu
PACKER_DIR  := packer
TERRAFORM_DIR := terraform
PKRVARS     := local.pkrvars.hcl
PKRFILE     := debian13-base.pkr.hcl
DEBIAN_SHA  := https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS
ANSIBLE_INVENTORY := ./ansible/hosts.yml
ANSIBLE_PLAYBOOK := ./ansible/set_hostname.yml
ANSIBLE_PRIVATE_KEY := ./packer/default_id_ed25519
ANSIBLE_USER := lab


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

k9s:		## Install k9s
	@$(call cyan, "Install k9s")
	@K9S_VERSION=$$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4); \
	if [ -z "$$K9S_VERSION" ]; then \
		echo "Pas d'accès à GitHub → utilisation d'une version connue stable"; \
		K9S_VERSION="v0.50.18"; \
	fi; \
	echo "Version k9s détectée/forcée : $$K9S_VERSION"; \
	sudo curl -L https://github.com/derailed/k9s/releases/download/$${K9S_VERSION}/k9s_Linux_amd64.tar.gz \
		-o /tmp/k9s.tar.gz; \
	sudo tar -xzf /tmp/k9s.tar.gz -C /tmp k9s; \
	sudo mv /tmp/k9s /usr/local/bin/k9s; \
	sudo chmod +x /usr/local/bin/k9s; \
	sudo rm -f /tmp/k9s.tar.gz; \
	echo "k9s installé avec succès !"

kubens:		## Install kubens
	@$(call cyan, "Install kubens")
	@curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens | sudo tee /usr/local/bin/kubens > /dev/null
	@sudo chmod +x /usr/local/bin/kubens
	@echo "kubens installé avec succès !"

kubectx:	## Install kubectx
	@$(call cyan, "Install kubectx")
	@curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx | sudo tee /usr/local/bin/kubectx > /dev/null
	@sudo chmod +x /usr/local/bin/kubectx
	@echo "kubectx installé avec succès !"

vm-ips:		## Show all VMs IP addresses
	@$(call cyan, "VMs IP addresses")
	@for vm in $$(sudo virsh list --name); do \
		echo "$$vm:"; \
		sudo virsh domifaddr $$vm 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "  no IP yet"; \
	done

logs-qemu:	## Show QEMU logs
	@$(call cyan, "Showing QEMU logs")
	sudo cat /var/log/libvirt/qemu/debian-vm.log | tail -50

terraform-fmt:	## Terraform fmt
	@$(call green, "Terraform fmt")
	cd $(TERRAFORM_DIR) && terraform fmt --recursive

terraform-validate:	## Terraform validate
	@$(call green, "Terraform validate")
	cd $(TERRAFORM_DIR) && terraform validate

terraform-init:	## Terraform init
	@$(call purple, "Terraform init")
	cd $(TERRAFORM_DIR) && terraform init --upgrade

terraform-apply:	## Terraform apply
	@$(call cyan, "Terraform apply")
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

terraform-destroy:	## Terraform destroy
	@$(call red, "Terraform destroy")
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

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

ansible:	## Ansible
	@$(call yellow, "Ansible")
	ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_PLAYBOOK) --ssh-extra-args='-o StrictHostKeyChecking=no' --private-key $(ANSIBLE_PRIVATE_KEY) -u $(ANSIBLE_USER)
