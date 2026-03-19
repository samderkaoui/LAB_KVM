# Guide de création de modules Terraform

Ce guide explique comment créer et utiliser des modules Terraform dans ce projet.

## Structure d'un module

Un module Terraform doit avoir la structure suivante :

```
modules/nom_du_module/
├── main.tf          # Ressources principales
├── variables.tf     # Variables d'entrée
├── outputs.tf       # Sorties du module
└── versions.tf      # Configuration des versions
```

## Gestion des versions

**Racine** (`terraform/versions.tf`) — fixe les versions exactes de tous les providers :
```hcl
libvirt = { source = "dmacvicar/libvirt", version = "= 0.9.5" }
```

**Module** (`modules/*/versions.tf`) — déclare uniquement les providers utilisés, avec des contraintes larges :
```hcl
libvirt = { source = "dmacvicar/libvirt", version = ">= 0.9.0" }
```

Règle : le module **déclare** ses providers (obligatoire), la racine **fixe** les versions (source de vérité unique). Pour upgrader un provider, on ne modifie que la racine.

## Gestion des variables

Le module déclare ses variables avec des défauts dans son `variables.tf` — c'est son contrat d'interface. La racine passe les valeurs via le bloc `module` dans `main.tf`, et son propre `variables.tf` sert uniquement à exposer des paramètres configurables depuis l'extérieur (`.tfvars`, `-var`).

```hcl
# modules/vm_k3s/variables.tf — contrat d'interface du module
variable "memory" {
  type    = number
  default = 2048
}

# terraform/variables.tf — expose le paramètre à l'extérieur (optionnel)
variable "vm_memory" {
  type    = number
  default = 4096
}

# terraform/main.tf — relaie la variable racine vers le module
module "vm_k3s" {
  source = "./modules/vm_k3s"
  memory = var.vm_memory  # via variable racine (configurable depuis l'extérieur)
  # memory = 5555         # ou valeur directe (hardcodé)
}
```

## Exemple : Module VM

Voici l'exemple du module `vm` qui crée une machine virtuelle KVM :

### variables.tf
```hcl
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
```

### main.tf
```hcl
resource "libvirt_volume" "disk" {
  name = "${var.vm_name}-base.qcow2"
  pool = "default"

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "file://${abspath(var.base_image)}"
    }
  }
}

resource "libvirt_domain" "vm" {
  name        = var.vm_name
  type        = "kvm"
  running     = true
  memory      = var.memory
  memory_unit = "MiB"
  vcpu        = var.vcpu

  # ... configuration complète
}
```

### outputs.tf
```hcl
output "vm_name" {
  value = libvirt_domain.vm.name
}
```

### versions.tf
```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.9.0"
    }
  }
}
```

## Utilisation d'un module

Pour utiliser un module dans votre configuration Terraform :

```hcl
module "ma_vm" {
  source     = "./modules/vm"
  vm_name    = "serveur-web"
  base_image = "./images/ubuntu-22.04.qcow2"
  memory     = 4096
  vcpu       = 4
  network    = "default"
}
```

## Bonnes pratiques

1. **Documentation** : Toujours documenter les variables avec `description`
2. **Valeurs par défaut** : Fournir des valeurs par défaut raisonnables
3. **Types de données** : Spécifier le type des variables
4. **Sorties utiles** : Exposer les informations importantes via `outputs`
5. **Versioning** : Définir les versions des providers dans `versions.tf`

## Création d'un nouveau module

Pour créer un nouveau module :

1. Créer un dossier dans `modules/` avec le nom du module
2. Ajouter les fichiers `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
3. Définir les ressources dans `main.tf`
4. Documenter les variables d'entrée dans `variables.tf`
5. Définir les sorties dans `outputs.tf`
6. Tester le module avec une configuration simple

## Tests

Pour tester un module, créez un fichier de test dans un répertoire séparé :

```hcl
# test/main.tf
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "= 0.9.5"  # version fixe ici car c'est une racine
    }
  }
}

module "test_vm" {
  source     = "../modules/vm"
  vm_name    = "test-vm"
  base_image = "../images/test-image.qcow2"
}
```

Puis exécutez :
```bash
terraform init
terraform plan
```

## Ressources utiles

- [Documentation Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)
- [Best Practices for Terraform Modules](https://developer.hashicorp.com/terraform/cloud-docs/registry/modules/publish)
- [Provider libvirt](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)
