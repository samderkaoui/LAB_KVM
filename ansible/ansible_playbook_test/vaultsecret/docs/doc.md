## Configuration de Vault

### 1. Activation et configuration des secrets
```bash
vault secrets enable -path=secret kv-v2
vault kv put secret/monapp/config db_password="MonSuperMotDePasse" api_key="abc123xyz"
```

### 2. Création de la politique d'accès
**Fichier : ansible-policy.hcl**
```hcl
path "secret/data/monapp/*" {
  capabilities = ["read", "list"]
}
```

```bash
vault policy write ansible-policy ansible-policy.hcl
```

### 3. Configuration de l'environnement
```bash
export VAULT_ADDR='http://vault.sam.com:8200'
vault token create -policy=ansible-policy -ttl=24h -display-name=ansible
```

### 4. Installation des dépendances Ansible
```bash
ansible-galaxy collection install community.hashi_vault
pip install hvac --break-system-packages
```

### 5. Gestion des secrets chiffrés
```bash
ansible-vault create vault_secrets.yml
```

**Contenu de vault_secrets.yml (chiffré):**
```yaml
vault_token: "hvs.XXXXXXXXXXXX"
```

### 6. Exécution du playbook
```bash
ansible-playbook playbook.yml --ask-vault-pass
```
