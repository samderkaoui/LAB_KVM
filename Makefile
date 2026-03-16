default: help

SHELL := /bin/bash -eu
PACKER_DIR  := packer
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

init:		## Packer init
	@$(call cyan, "Packer init")
	cd $(PACKER_DIR) && packer init .

build:		## Packer build
	@$(call green, "Packer build")
	cd $(PACKER_DIR) && packer build -var-file=$(PKRVARS) $(PKRFILE)

sha256:		## Get Debian netinst SHA256
	@$(call yellow, "Fetching Debian netinst SHA256")
	@curl -s $(DEBIAN_SHA) | grep netinst

destroy:	## Clean packer output
	@$(call red, "Removing packer output")
	rm -rf $(PACKER_DIR)/output
