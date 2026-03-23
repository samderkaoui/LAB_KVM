# Keycloak + GitLab : SSO & gestion des droits

## Vue d'ensemble du flux

```
User navigateur  →  GitLab  →  "Login with Keycloak"
                          ↓
                     Keycloak (authentification)
                          ↓
                     Retour token OIDC → GitLab crée/connecte le compte
```

GitLab utilise **OpenID Connect (OIDC)** pour déléguer l'auth à Keycloak. Les rôles Keycloak seront mappés aux groupes GitLab.

---

## Étape 1 — Keycloak : créer un Realm

Un **Realm** = ton espace d'isolation. Ne pas utiliser `master` en prod.

1. Connecte-toi sur `http://keycloak.sam.com:8080` → admin/changeme
2. Menu haut gauche → **Create Realm**
3. Nom : `homelab` → **Create**

---

## Étape 2 — Keycloak : créer le Client GitLab

Un **Client** = une application qui va s'authentifier via Keycloak.

1. Dans le realm `homelab` → **Clients** → **Create client**
2. Remplis :
   - **Client type** : `OpenID Connect`
   - **Client ID** : `gitlab`
3. Page suivante :
   - **Client authentication** : `ON` (→ génère un secret)
   - **Standard flow** : `ON`
4. Page suivante — **Valid redirect URIs** :
   ```
   http://gitlab.sam.com/users/auth/openid_connect/callback
   ```
5. **Save**

Ensuite : onglet **Credentials** → copie le **Client secret** (tu en auras besoin).

---

## Étape 3 — Keycloak : créer les rôles

Les rôles vont définir ce que les users peuvent faire dans GitLab.

**Clients** → `gitlab` → onglet **Roles** → **Create role** :

| Rôle à créer | Usage GitLab |
|---|---|
| `gitlab-admin` | Administrateur GitLab |
| `gitlab-developer` | Developer sur les projets |
| `gitlab-guest` | Accès lecture seule |

---

## Étape 4 — Keycloak : créer des utilisateurs et assigner les rôles

1. **Users** → **Create user**
   - Username : `alice`
   - Email : `alice@sam.com`
   - **Create**
2. Onglet **Credentials** → **Set password** → désactive "Temporary"
3. Onglet **Role mapping** → **Assign role** → filtre par client `gitlab` → assigne `gitlab-developer`

Répète pour chaque utilisateur avec le rôle souhaité.

---

## Étape 5 — Keycloak : exposer les rôles dans le token

Par défaut les rôles ne sont pas inclus dans le token OIDC. Il faut ajouter un **mapper**.

**Clients** → `gitlab` → onglet **Client scopes** → clique sur `gitlab-dedicated` → **Add mapper** → **By configuration** → **User Client Role** :

- **Name** : `gitlab-roles`
- **Client ID** : `gitlab`
- **Token Claim Name** : `roles`
- **Add to ID token** : `ON`
- **Add to userinfo** : `ON`

---

## Étape 6 — GitLab : configurer OIDC

Modifie ton `docker-compose.yml`, section `GITLAB_OMNIBUS_CONFIG` :

```yaml
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.sam.com'
        gitlab_rails['omniauth_enabled'] = true
        gitlab_rails['omniauth_allow_single_sign_on'] = ['openid_connect']
        gitlab_rails['omniauth_block_auto_created_users'] = false
        gitlab_rails['omniauth_auto_link_user'] = ['openid_connect']

        gitlab_rails['omniauth_providers'] = [
            {
            name: 'openid_connect',
            label: 'Keycloak SSO',
            args: {
                name: 'openid_connect',
                scope: ['openid', 'profile', 'email', 'roles'],
                response_type: 'code',
                issuer: 'http://keycloak.sam.com:8080/realms/homelab',
                client_auth_method: 'query',
                discovery: false,    ======> j'ai mis en false car http et je dois hardcodé les urls qui sont renvoyés (jwks_uri to end_session_endpoint en HTTPS par defaut
                uid_field: 'preferred_username',
                jwks_uri: 'http://keycloak.sam.com:8080/realms/homelab/protocol/openid-connect/certs',
                authorization_endpoint: 'http://keycloak.sam.com:8080/realms/homelab/protocol/openid-connect/auth',
                token_endpoint: 'http://keycloak.sam.com:8080/realms/homelab/protocol/openid-connect/token',
                userinfo_endpoint: 'http://keycloak.sam.com:8080/realms/homelab/protocol/openid-connect/userinfo',
                end_session_endpoint: 'http://keycloak.sam.com:8080/realms/homelab/protocol/openid-connect/logout',
                client_options: {
                identifier: 'gitlab',
                secret: 'EBubHamGidRHkO08YBpsltm1MAYhbRkH',
                redirect_uri: 'http://gitlab.sam.com/users/auth/openid_connect/callback',
                scheme: 'http', ======> je force le HTTP
                host: 'keycloak.sam.com' ======> Sans discovery, GitLab ne sait plus quel host appeler pour les échanges de tokens — il faut le lui dire explicitement.
                port: 8080 ======> le port (comme ca explicite et pas directe 443
                }
            }
            }
        ]
```

Puis :
```bash
docker compose up -d --force-recreate web
```

---

## Étape 7 — Mapper les rôles Keycloak → droits GitLab

GitLab ne lit pas les rôles Keycloak nativement pour les droits projets — il y a deux approches :

### Approche A — Groupes GitLab automatiques (la plus propre)  (le Group sync via OIDC n'existe pas en GitLab CE, c'est une fonctionnalité GitLab EE (payant) uniquement.)

Dans GitLab : **Admin** → **Settings** → **General** → **Sign-in restrictions** → active **Group sync**.

Crée des groupes GitLab avec les noms correspondants aux rôles Keycloak. Les users sont auto-assignés à leur groupe à la connexion.

### Approche B — Rôle admin via `omniauth`

Pour donner les droits admin GitLab automatiquement :

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: 'openid_connect',
    label: 'Keycloak SSO',
    args: {
      ...
      groups_attribute: 'roles',
      admin_groups: ['gitlab-admin'],
      ...
    }
  }
]
```

---

## Résumé du flux complet

```
1. User arrive sur gitlab.sam.com
2. Clique "Keycloak SSO"
3. Redirigé vers keycloak.sam.com → s'authentifie
4. Keycloak retourne un token OIDC avec { roles: ["gitlab-developer"] }
5. GitLab reçoit le token, crée/connecte le compte
6. Les rôles/groupes sont appliqués
```
