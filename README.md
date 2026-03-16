# LAB KVM

## Prérequis

Créer le fichier `packer/local.pkrvars.hcl` :

```hcl
ssh_username = "lab" # valeur souhaitée
ssh_password = "lab" # valeur souhaitée
iso_checksum = "sha256:<CHECKSUM>"  # obtenir avec : make sha256
```

## Usage

```bash
make help       # Liste les commandes disponibles
make sha256     # Récupère le SHA256 du netinst Debian courant
make init       # Initialise les plugins Packer
make build      # Build l'image de base Debian
make destroy    # Supprime le packer output
```

## Workflow

```bash
# 1. Récupérer le checksum et le copier dans local.pkrvars.hcl
make sha256

# 2. Initialiser Packer
make init

# 3. Build
make build
```
