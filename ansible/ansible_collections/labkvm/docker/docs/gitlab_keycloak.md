# Problème keycloak virtualisation 

```bash
virsh edit <nom-de-ta-vm>

# expose directement les instructions CPU de l'hôte à la VM,nécessaire pour que Keycloak (ou d'autres apps) puissent utiliser les extensions CPU avancées 
<cpu mode='host-passthrough' check='none'/>

# Le reboot semble ne pas suffir
sudo virsh destroy gitlab
sudo virsh start gitlab
```

# Gitlab

```bash
# Se connecter a gitlab et récupérer le token pour relier le runner au gitlab
# Puis lancer la commande
sudo docker exec -ti gitlab-runner gitlab-runner register  --url http://gitlab.sam.com  --token glrt-xxxxxxxxx

# Configurer le runner pour avoir l'ip/dns de mon gitlab
# /var/gitll/gitlab-runner/config.toml sous [runners.docker]
extra_hosts = ["gitlab.sam.com:172.30.0.2"]
network_mode = "gitlab-network" 

```
