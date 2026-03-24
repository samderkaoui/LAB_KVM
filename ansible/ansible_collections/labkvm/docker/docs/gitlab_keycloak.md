### Étape 5 : Configuration Manuel Gitlab / keycloak (pas d'overengineering :) )

```bash
virsh edit gitlab (nom de la vm)

# expose directement les instructions CPU de l'hôte à la VM,nécessaire pour que Keycloak (ou d'autres apps) puissent utiliser les extensions CPU avancées 
<cpu mode='host-passthrough' check='none'/>

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
```

```bash
# Se connecter a gitlab et récupérer le token pour relier le runner au gitlab
# Puis lancer la commande
sudo docker exec -ti gitlab-runner gitlab-runner register  --url https://gitlab.sam.com  --token xxxxxxxxxxxxxxxxxxxxxxxxx --tls-ca-file /etc/gitlab-runner/certs/gitkc.crt

# Configurer le runner pour avoir l'ip/dns de mon gitlab/keycloak via TRAEFIK (donc ip du reverse et pas des conteneurs)
# /var/gitll/gitlab-runner/config.toml sous [runners.docker]
extra_hosts = ["gitlab.sam.com:172.30.0.6", "keycloak.sam.com:172.30.0.6"]
network_mode = "gitlab-network" 
# si necessaire : volumes = ["/var/gitll/certs/gitkc.crt:/usr/local/share/ca-certificates/gitkc.crt"]
```

- Faire la conf manuel keycloak (voir doc)
- maj du token dans le docker-compose
- rm -f gitlab-ce
- docker compose up -d
