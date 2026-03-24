# HashiCorp Vault — Docker Compose (Homelab)

## Structure
```
vault/
├── docker-compose.yml
├── config/
│   └── vault.hcl          # configuration Vault
├── init-vault.sh           # script d'init (premier démarrage)
└── vault-init-keys.json    # généré à l'init — À PROTÉGER
```

## Démarrage rapide

```bash
# 1. Lancer Vault
docker compose up -d

# 2. Initialiser (une seule fois)
chmod +x init-vault.sh && bash init-vault.sh

# 3. Accéder à l'UI
open http://localhost:8200/ui
```

## Après chaque redémarrage (unseal)

Vault se re-scelle automatiquement au redémarrage. Relancer simplement le script d'init, il détecte l'état et fait uniquement l'unseal :

```bash
bash init-vault.sh
```

## Premiers secrets

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
vault login <root_token>

# Activer le moteur KV v2
vault secrets enable -path=secret kv-v2

# Écrire un secret
vault kv put secret/homelab/ssh private_key="..."

# Lire
vault kv get secret/homelab/ssh
```

## Intégration Kubernetes (k3s)

```bash
# Activer l'auth Kubernetes
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://<k3s-api>:6443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Créer une policy + role pour un namespace
vault policy write my-app - <<EOF
path "secret/data/homelab/*" {
  capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/my-app \
  bound_service_account_names=my-app \
  bound_service_account_namespaces=default \
  policies=my-app \
  ttl=1h
```

## Sécurisation (étapes suivantes)

- [ ] Activer TLS (cert Let's Encrypt ou self-signed)  
- [ ] Chiffrer / déplacer `vault-init-keys.json`  
- [ ] Créer des tokens avec policies limitées (ne plus utiliser root)  
- [ ] Configurer Auto-Unseal avec une clé externe (Transit, cloud KMS)  
- [ ] Activer audit log : `vault audit enable file file_path=/vault/logs/audit.log`
