# Keycloak + Vault : OIDC Authentication

## Vue d'ensemble du flux

```
User navigateur  →  Vault UI  →  "Sign in with OIDC"
                          ↓
                     Keycloak (authentification)
                          ↓
                     Retour token OIDC → Vault mappe les rôles/policies
```

Vault utilise **OpenID Connect (OIDC)** pour déléguer l'auth à Keycloak. Les rôles Keycloak seront mappés aux **policies Vault**.

---

## Prérequis

- Realm Keycloak `homelab` déjà créé (voir `keycloak_fonctionnement.md`)
- Vault accessible sur `https://vault.sam.com`
- Vault initialisé et unsealed

---

## Étape 1 — Keycloak : créer le Client Vault

1. Connecte-toi sur `http://keycloak.sam.com:8080` → admin/changeme
2. Realm `homelab` → **Clients** → **Create client**
3. Remplis :
   - **Client type** : `OpenID Connect`
   - **Client ID** : `vault`
4. Page suivante :
   - **Client authentication** : `ON` (→ génère un secret)
   - **Standard flow** : `ON`
5. Page suivante — **Valid redirect URIs** :
   ```
   https://vault.sam.com/ui/vault/auth/oidc/oidc/callback
   http://localhost:8250/oidc/callback
   http://vault.sam.com:8200/ui/vault/auth/oidc/oidc/callback
   ```
   > Le `localhost:8250` est nécessaire pour l'auth via CLI (`vault login -method=oidc`)
6. **Save**

Onglet **Credentials** → copie le **Client secret**.

---

## Étape 2 — Keycloak : créer les rôles Vault

**Clients** → `vault` → onglet **Roles** → **Create role** :

| Rôle à créer | Usage Vault |
|---|---|
| `vault-admin` | Policy `admin` (accès total) |
| `vault-reader` | Policy `read-only` (lecture des secrets) |
| `vault-developer` | Policy `developer` (accès secrets/dev) |

---

## Étape 3 — Keycloak : assigner les rôles aux utilisateurs

1. **Users** → sélectionne un utilisateur (ex: `alice`)
2. Onglet **Role mapping** → **Assign role** → filtre par client `vault` → assigne le rôle souhaité

---

## Étape 4 — Keycloak : exposer les rôles dans le token

**Clients** → `vault` → onglet **Client scopes** → clique sur `vault-dedicated` → **Add mapper** → **By configuration** → **User Client Role** :

- **Name** : `vault-roles`
- **Client ID** : `vault`
- **Token Claim Name** : `roles`
- **Add to ID token** : `ON`
- **Add to userinfo** : `ON`
- **Add to access token** : `ON`

---

## Étape 5 — Vault : activer le backend OIDC

Connecte-toi à Vault ( docker exec -ti vault sh)

```bash
export VAULT_SKIP_VERIFY=true

# Ajouter l'entrée DNS pour keycloak.sam.com dans /etc/hosts
echo "192.168.122.112 keycloak.sam.com" >> /etc/hosts

echo "192.168.122.20 vault.sam.com" >> /etc/hosts

export VAULT_ADDR='http://vault.sam.com:8200'
```

Active l'auth method OIDC :

```bash
vault auth enable oidc
```

Configure le provider Keycloak :

```bash
# copier le CA depuis VM gitlab :
scp gitkc.crt lab@192.168.122.20:/home/lab
# La mettre sur le conteneur dans /root/
docker cp /home/lab/gitkc.crt vault:/root/gitkc.crt
# commande finale
vault write auth/oidc/config oidc_discovery_url="https://keycloak.sam.com/realms/homelab" oidc_client_id="vault" oidc_client_secret="chNkL12jLpgh1B1UW40JYHN5qMob5dC3" default_role="admin" oidc_discovery_ca_pem=@/root/gitkc.crt
```

---

## Étape 6 — Vault : créer les policies

Crée les policies qui seront assignées via les rôles Keycloak.

**Policy `admin`** :
```bash
## dans admin.hcl
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

vault policy write adminkeycloak admin.hcl


```

---

## Étape 7 — Vault : créer les rôles OIDC

Chaque rôle OIDC fait le lien entre un rôle Keycloak et une policy Vault.

**Rôle `admin`** (mappe le rôle Keycloak `vault-admin`) :
```bash
apk add vim

## vim /tmp/role.json
{
  "bound_audiences": "vault",
  "allowed_redirect_uris": [
    "https://vault.sam.com/ui/vault/auth/oidc/oidc/callback",
    "http://vault.sam.com:8200/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback"
  ],
  "user_claim": "preferred_username",
  "bound_claims": {"roles": ["vault-admin"]},
  "bound_claims_type": "glob",
  "claim_mappings": {},
  "token_policies": ["adminkeycloak"],
  "token_ttl": "1h"
}

vault write auth/oidc/role/admin @/tmp/role.json
# debug 
# vault write auth/oidc/role/admin verbose_oidc_logging=true @/tmp/role.json
# vault monitor -log-level=debug 2>&1 | grep -i oidc
# vault monitor -log-level=debug 2>&1 | grep -v "^$"


```

---

## Étape 8 — Test de connexion

### Via l'UI Vault

1. Ouvre `https://vault.sam.com/ui`
2. **Sign in** → méthode : `OIDC` → rôle : `admin` (ou laisser vide pour le défaut)
3. Clique **Sign in with OIDC Provider** → redirigé vers Keycloak
4. S'authentifie → retour sur Vault avec les droits associés

---

## Résumé du flux complet

```
1. User arrive sur vault.sam.com/ui
2. Choisit méthode OIDC + rôle (ex: "admin")
3. Redirigé vers keycloak.sam.com → s'authentifie
4. Keycloak retourne un token OIDC avec { roles: ["vault-admin"] }
5. Vault vérifie bound_claims → rôle "admin" correspond
6. Vault applique la policy "admin" → accès accordé
```

---

## Dépannage

| Problème | Cause probable | Solution |
|---|---|---|
| `error: redirect_uri mismatch` | URI de redirect non enregistrée dans Keycloak | Vérifier les **Valid redirect URIs** du client `vault` |
| `claim not found: roles` | Mapper absent ou mal configuré | Vérifier l'étape 4 (mapper `vault-roles`) |
| `no roles assigned` | User sans rôle Keycloak | Assigner le rôle dans **Role mapping** (étape 3) |
| Token expiré immédiatement | `token_ttl` trop court | Augmenter `token_ttl` dans le rôle OIDC |
