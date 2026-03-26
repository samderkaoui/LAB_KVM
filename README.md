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

- [ ] Cree une VM en plus pour vault / Finir de tester le dockercompose ( ne pas utiliser les script auto , trop d overengineering) / Puis faire l'install avec ansible (new role) comme gitlab (avec traefik et HTTPS aussi :) )
- [ ] Refaire image packer avec 40 gb de disque ( 20 trop light)
- [ ] Refaire les vm , install gitlab / keycloack etc...
- [ ] retirer taint k3s master = kubectl taint nodes xxxxxx node-role.kubernetes.io/control-plane:NoSchedule-
- [ ] Deployer metrics server " kubectl apply -f /vagrant/manifests/metrics-server.yaml "
- [ ] Importer chart longhorn pour le stockage
- [ ] Importer premier chart helm argocd pour configurer argo
- [ ] Importer chart kube-prom-stack pour l'obs
- [ ] KubeadmVagrant/install/todo_manual.sh => METALLB / API GATEWAY / CERT MANAGER / etc...

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
make prerequis         # Configure QEMU (user root + security_driver none) + installe python3/kubectl/fzf + crée le venv ansible-lint
```

### Outils Kubernetes locaux
```bash
make k9s               # Installe k9s (détecte automatiquement la dernière version)
make kubens            # Installe kubens
make kubectx           # Installe kubectx
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
make terraform-fmt      # Formate les fichiers Terraform
make terraform-validate # Valide la configuration Terraform
make terraform-init     # Initialise les providers Terraform
make terraform-apply    # Crée/met à jour les VMs
make terraform-destroy  # Supprime les VMs
```

### Ansible - Configuration
```bash
make ansible           # Exécute le playbook Ansible pour configurer les hôtes
```

### Linting
```bash
make ansible-lint-install  # Installe ansible-lint dans le venv (.venv/ansible-lint)
make tflint-install        # Installe tflint (détecte automatiquement la dernière version)
make tfsec-install         # Installe tfsec (détecte automatiquement la dernière version)
make ansible-lint          # Lint le répertoire ansible/
make terraform-lint        # Lint le répertoire terraform/
make tfsec                 # Analyse de sécurité du répertoire terraform/
```

## Workflow complet

### Étape 1 : Configuration initiale (une seule fois)
```bash
# Configure QEMU, installe python3/kubectl/fzf et crée le venv ansible-lint
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

### Étape 5 : Configuration Manuel Gitlab / keycloak (pas d'overengineering :) )

```bash
sudo virsh edit gitlab (nom de la vm)

# expose directement les instructions CPU de l'hôte à la VM,nécessaire pour que Keycloak (ou d'autres apps) puissent utiliser les extensions CPU avancées 
<cpu mode='host-passthrough' check='none'/>  # (ne pas mettre /cpu a la fin car j'ai /)

# Le reboot semble ne pas suffir
sudo virsh destroy gitlab
sudo virsh start gitlab
```

```bash
# Configurer mon /etc/hosts local
127.0.0.1	localhost
127.0.1.1	DedSec.lan	DedSec

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
192.168.122.156 gitlab.sam.com
192.168.122.156 keycloak.sam.com
xxxxxxxxxxxxxxx   vault.sam.com
```

```bash
# Se connecter a gitlab et récupérer le token pour relier le runner au gitlab
# Puis lancer la commande
sudo docker exec -ti gitlab-runner gitlab-runner register  --url https://gitlab.sam.com  --token xxxxxxxxxxxxxxxxxxxxxxxxx --tls-ca-file /etc/gitlab-runner/certs/gitkc.crt

# Configurer le runner pour avoir l'ip/dns de mon gitlab/keycloak via TRAEFIK (donc ip du reverse et pas des conteneurs)
# /var/gitll/gitlab-runner/config.toml sous [runners.docker]
extra_hosts = ["gitlab.sam.com:172.30.0.6", "keycloak.sam.com:172.30.0.6", "vault.sam.com:IP AD DEFINIR A LA MAIN"]
network_mode = "gitlab-network" 
# si necessaire : volumes = ["/var/gitll/certs/gitkc.crt:/usr/local/share/ca-certificates/gitkc.crt"]
```

- Faire la conf manuel keycloak (voir doc ansible_collections/labkvm/docker/docs/keycloak_fonctionnement.md)
- maj du token dans le docker-compose
- rm -f gitlab-ce
- docker compose up -d


```bash
# Installer / unseal vault
bash /var/vault/init-vault.sh
```


### Étape 6 : Nettoyage (si nécessaire)
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
│   ├── local.pkrvars.hcl      # Variables Packer ( id / pw et checksum)
│   ├── default_id_ed25519     # Clé SSH pour Packer créée par le playbook ansible utilisé lors du packer build
│   ├── http/                  # Fichiers de provisionnement HTTP pour packer
│   └── output/                # Images générées
├── terraform/            # Configuration Terraform
│   ├── main.tf           # Configuration principale
│   ├── variables.tf      # Variables Terraform
│   ├── providers.tf      # Configuration des providers
│   ├── versions.tf       # Définition des version des providers
│   ├── outputs.tf        # Sorties Terraform
│   └── modules/          # Modules Terraform
├── ansible/              # Configuration Ansible
│   ├── hosts.yml              # Inventaire des hôtes ( généré par Terraform )
│   ├── site.yml               # Playbook principal
│   ├── base_packer.yml        # Playbook de base utilisé pour packer
│   ├── ansible_collections/   # Collections Ansible (ANSIBLE_COLLECTIONS_PATH)
├── .venv/
│   └── ansible-lint/          # Venv Python pour ansible-lint (créé par make prerequis)
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
