# LAB KVM

## Prérequis

Créer le fichier `packer/local.pkrvars.hcl` :

```hcl
ssh_username = "lab" # valeur souhaitée
ssh_password = "lab" # valeur souhaitée
iso_checksum = "sha256:<CHECKSUM>"  # obtenir avec : make sha256
```

## Usage

### Prérequis système

```bash
make prerequis        # Configure QEMU (user root + security_driver none)
```

### Packer

```bash
make sha256           # Récupère le SHA256 du netinst Debian courant
make packer-init             # Initialise les plugins Packer
make packer-build            # Build l'image de base Debian
make packer-destroy          # Supprime le packer output
```

### Terraform

```bash
make terraform-init   # Initialise les providers Terraform
make terraform-apply  # Crée/met à jour la/les VM
make terraform-destroy # Supprime la/les VM
make terraform-fmt    # Formate les fichiers .tf
```

### VM

```bash
make vm-ips           # Affiche les IPs de toutes les VMs en cours d'exécution
make logs-qemu        # Affiche les 50 dernières lignes de logs QEMU
```

```bash
make help             # Liste toutes les commandes disponibles
```

## Workflow

```bash
# 1. Configurer QEMU (une seule fois)
make prerequis

# 2. Récupérer le checksum et le copier dans local.pkrvars.hcl
make sha256

# 3. Initialiser et builder l'image Packer
make init
make build

# 4. Déployer la VM avec Terraform
make terraform-init
make terraform-apply

# 5. Récupérer l'IP des VM's
make vm-ips
```
