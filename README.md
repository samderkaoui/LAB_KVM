# LAB KVM - Infrastructure as Code avec Packer, Terraform et Ansible

Ce projet permet de créer et gérer des machines virtuelles KVM avec une approche Infrastructure as Code (IaC) en utilisant Packer pour construire des images de base, Terraform pour le provisionnement d'infrastructure et Ansible pour la configuration.

## Table des matières

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Commandes disponibles](#commandes-disponibles)
- [Workflow complet](#workflow-complet)
- [Structure du projet](#structure-du-projet)
- [Configuration](#configuration)
- [Dépannage](#dépannage)

## To DO
✅ ⛔
- [ ] Créer une collection ansible pour tout configurer (role , import_playbook/tasks) => install k3s master/worker , Configuration GITLAB ( Dockerisé avec module ansible) et un playbook unique comme point d'entrer ( pour le makefile ) et un role pour l'example ( juste fera un apt update comme task)
- [ ] Importer premier chart helm

## Prérequis

### Logiciels requis

- **Make** : Pour exécuter les commandes automatisées
- **Packer** : Pour construire les images de machine virtuelle
- **Terraform** : Pour provisionner l'infrastructure
- **Ansible** : Pour la configuration des machines
- **QEMU/KVM** : Pour l'hyperviseur de virtualisation
- **Libvirt** : Pour la gestion des machines virtuelles

### Configuration système

Avant de commencer, assurez-vous que votre utilisateur fait partie du groupe `libvirt` :

```bash
sudo usermod -a -G libvirt $USER
newgrp libvirt
```

## Installation

1. Clonez le dépôt :
```bash
git clone <repository-url>
cd LAB_KVM
```

2. Configurez le fichier de variables Packer :
```bash
cp packer/local.pkrvars.hcl.example packer/local.pkrvars.hcl
```

3. Éditez le fichier `packer/local.pkrvars.hcl` avec vos valeurs :
```hcl
ssh_username = "lab"
ssh_password = "lab"
iso_checksum = "sha256:<CHECKSUM>"  # Obtenez le checksum avec : make sha256
```

## Commandes disponibles

Le projet utilise un Makefile avec les commandes suivantes :

### Aide et informations
```bash
make help              # Affiche toutes les commandes disponibles
make vm-ips            # Affiche les adresses IP de toutes les VMs en cours
make logs-qemu         # Affiche les 50 dernières lignes des logs QEMU
```

### Configuration système
```bash
make prerequis         # Configure QEMU (user root + security_driver none)
```

### Packer - Construction d'images
```bash
make sha256            # Récupère le SHA256 de l'ISO Debian netinst courant
make packer-init       # Initialise les plugins Packer
make packer-build      # Construit l'image de base Debian
make packer-destroy    # Supprime les fichiers de sortie de Packer
```

### Terraform - Provisionnement d'infrastructure
```bash
make terraform-fmt     # Formate les fichiers Terraform
make terraform-validate # Valide la configuration Terraform
make terraform-init    # Initialise les providers Terraform
make terraform-apply   # Crée/met à jour les VMs
make terraform-destroy # Supprime les VMs
```

### Ansible - Configuration
```bash
make ansible           # Exécute le playbook Ansible pour configurer les hôtes
```

## Workflow complet

### Étape 1 : Configuration initiale (une seule fois)
```bash
# Configurez QEMU pour fonctionner avec les permissions appropriées
make prerequis

# Récupérez le checksum SHA256 de l'ISO Debian
make sha256

# Copiez le checksum dans packer/local.pkrvars.hcl
# Éditez le fichier et remplacez <CHECKSUM> par la valeur obtenue
```

### Étape 2 : Construction de l'image de base avec Packer
```bash
# Initialisez Packer
make packer-init

# Construisez l'image Debian
make packer-build
```

### Étape 3 : Déploiement des VMs avec Terraform
```bash
# Initialisez Terraform
make terraform-init

# Validez la configuration
make terraform-validate

# Appliquez la configuration pour créer les VMs
make terraform-apply
```

### Étape 4 : Configuration avec Ansible
```bash
# Vérifiez que les VMs ont des adresses IP
make vm-ips

# Terraform génère automatiquement le fichier ansible/hosts.yml avec les bonnes adresses IP
# Exécutez Ansible pour configurer les hôtes
make ansible
```

### Étape 5 : Nettoyage (si nécessaire)
```bash
# Pour détruire les VMs mais conserver l'image
make terraform-destroy

# Pour nettoyer complètement (VMs + image)
make terraform-destroy
make packer-destroy
```

## Structure du projet

```
LAB_KVM/
├── Makefile              # Automatisation des commandes
├── packer/               # Configuration Packer
│   ├── debian13-base.pkr.hcl  # Définition de l'image
│   ├── local.pkrvars.hcl      # Variables Packer
│   ├── default_id_ed25519     # Clé SSH pour Packer
│   ├── http/                  # Fichiers de provisionnement HTTP
│   └── output/                # Images générées
├── terraform/            # Configuration Terraform
│   ├── main.tf           # Configuration principale
│   ├── variables.tf      # Variables Terraform
│   ├── providers.tf      # Définition des providers
│   ├── outputs.tf        # Sorties Terraform
│   └── modules/          # Modules Terraform
├── ansible/              # Configuration Ansible
│   ├── hosts.yml         # Inventaire des hôtes
│   ├── set_hostname.yml  # Playbook principal
│   ├── base.yml          # Playbook de base
│   └── k3s/              # Configuration K3s
└── README.md             # Documentation
```

## Configuration

### Fichier de variables Packer (`packer/local.pkrvars.hcl`)

Ce fichier contient les variables spécifiques à votre environnement :
- `ssh_username` : Nom d'utilisateur pour SSH
- `ssh_password` : Mot de passe pour SSH
- `iso_checksum` : Checksum SHA256 de l'ISO Debian

### Variables Terraform (`terraform/variables.tf`)

Le projet utilise les variables Terraform suivantes :

- `base_image` : Chemin vers l'image Debian générée par Packer (par défaut : `"../packer/output/debian13-base.qcow2"`)

Sinon pour modifier le nom des VM's, la RAM etc... ca se passe dans : ***terraform/main.tf***

### Provider Terraform

Le projet utilise le provider `libvirt` pour gérer les machines virtuelles KVM. La configuration par défaut utilise l'URI `qemu:///system`. Assurez-vous que :
1. Votre utilisateur a les permissions nécessaires pour accéder à libvirt
2. Le service libvirtd est en cours d'exécution
3. Vous avez installé les outils libvirt et QEMU/KVM

### Sorties Terraform

Après l'exécution de `terraform-apply`, Terraform affiche les sorties suivantes qui contiennent des informations importantes sur les VMs créées :

- `vm_k3s_master_name` : Nom de la VM master
- `vm_k3s_master_ip` : Adresse IP de la VM master
- `vm_k3s_worker_1_name` : Nom du premier worker
- `vm_k3s_worker_1_ip` : Adresse IP du premier worker
- `vm_k3s_worker_2_name` : Nom du deuxième worker
- `vm_k3s_worker_2_ip` : Adresse IP du deuxième worker

**Note technique** : Les adresses IP sont récupérées automatiquement par Terraform à l'aide d'un script qui interroge libvirt pour obtenir les adresses IP attribuées aux VMs via DHCP. Ce processus peut prendre quelques minutes après la création des VMs.

Ces informations sont également utilisées pour générer automatiquement l'inventaire Ansible.

### Inventaire Ansible (`ansible/hosts.yml`)

**Note importante** : Ce fichier est généré automatiquement par Terraform après l'exécution de `terraform-apply`. Terraform récupère les adresses IP des VMs créées et met à jour le fichier d'inventaire avec les bonnes adresses.

Exemple de contenu généré :
```yaml
all:
  children:
    masters:
      hosts:
        k3s-master:
          ansible_host: 192.168.122.77
    workers:
      hosts:
        k3s-worker-1:
          ansible_host: 192.168.122.19
        k3s-worker-2:
          ansible_host: 192.168.122.117
```

Vous n'avez pas besoin de modifier ce fichier manuellement. Il est mis à jour automatiquement à chaque exécution de `terraform-apply`.
