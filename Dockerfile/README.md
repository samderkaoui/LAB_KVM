# Dockerfile — Multi-stage build Node.js

Exemple d'un Dockerfile optimisé pour une app Node.js.

## Structure

```
Dockerfile/
├── Dockerfile          # Image multi-stage (2 stages)
├── docker-compose.yml  # Lance l'image en production
├── .dockerignore       # Fichiers exclus du build context
├── package.json
└── src/
    └── index.js        # Serveur HTTP d'exemple
```

---

## Concept clé : le multi-stage build

Un multi-stage build utilise **plusieurs blocs `FROM`** dans le même Dockerfile.
Chaque bloc est un stage indépendant. Docker les construit dans l'ordre, mais **seul le dernier stage est gardé** dans l'image finale.

```
┌─────────────────────────────────┐     ┌──────────────────────────────────┐
│  Stage 1 : builder              │     │  Stage 2 : production            │
│  (conteneur temporaire)         │     │  (image finale livrée)           │
│                                 │     │                                  │
│  node:22-alpine                 │     │  node:22-alpine  (base vierge)   │
│  + toutes les dépendances       │     │  + dépendances prod seulement    │
│  + devDependencies              │ ──► │  + dist/ copié depuis stage 1    │
│  npm run build → dist/          │     │  + user non-root                 │
│                                 │     │                                  │
│  JETÉ après le build            │     │  ~80 MB  (vs ~400 MB sans ça)    │
└─────────────────────────────────┘     └──────────────────────────────────┘
```

**Résultat** : l'image finale ne contient pas les outils de build, pas les devDependencies, uniquement ce qui est nécessaire pour faire tourner l'app.

---

## Ce que fait chaque stage

### Stage 1 — `builder`

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install                       # installe TOUT (dev + prod)
COPY src/ ./src/
RUN npm run build                     # génère dist/ depuis src/
```

Ce stage compile l'app. Il est **temporaire** : Docker ne le garde pas dans l'image finale.

### Stage 2 — `production`

```dockerfile
FROM node:22-alpine AS production     # repart de zéro, image vierge
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev               # installe uniquement les dépendances de prod
COPY --from=builder /app/dist ./dist      # récupère dist/ depuis le stage 1
USER appuser
CMD ["node", "dist/index.js"]
```

Ce stage construit l'image finale. La ligne clé est `COPY --from=builder` : elle extrait uniquement le dossier `dist/` du stage 1, sans embarquer les outils de build.

---

## docker-compose.yml

```yaml
build:
  target: production   # cible explicitement le stage "production"
```

`target: production` indique à Docker de s'arrêter au stage nommé `production`.
Ici c'est inutile (c'est déjà le dernier stage), mais c'est une bonne pratique pour documenter l'intention et éviter des surprises si on ajoute un stage plus tard.

---

## Utilisation

```bash
# Lancer en production
docker compose up -d

# L'app répond sur http://localhost:3000

# Build uniquement (sans démarrer)
docker compose build .

# Debug : builder le stage 1 seulement (avec devDependencies)
docker build --target builder -t my-app:dev .

# Inspecter la taille des layers de l'image finale
docker history my-app:latest
```

---

## Best practices appliquées

| Pratique | Pourquoi |
|---|---|
| Base `alpine` | ~5 MB au lieu de ~300 MB |
| `COPY package*.json` avant le code source | Docker cache les dépendances — rebuild plus rapide si seul le code change |
| `npm install --omit=dev` en prod | Exclut les devDependencies de l'image finale |

| `npm cache clean --force` dans le même `RUN` | Évite un layer supplémentaire avec le cache npm |
| User non-root (`adduser`) | Si le conteneur est compromis, l'attaquant n'a pas les droits root |
| `CMD ["node", ...]` (exec form) | Le processus reçoit directement SIGTERM — arrêt propre |
| `.dockerignore` | Exclut `node_modules`, `.git` etc. — build context plus léger |

---

## Adapter à d'autres stacks

La logique est toujours la même : **stage lourd pour compiler → copie du résultat → image légère**.

| Stack | Stage 1 | Stage 2 |
|---|---|---|
| **Python** | `FROM python:3.12-slim`, `pip install` | `COPY --from=builder /usr/local/lib/python3.12/site-packages` |
| **Go** | `FROM golang:1.22`, `go build -o app` | `FROM scratch` (0 MB de base) + `COPY --from=builder /app/app .` |
| **Java** | `FROM maven:3.9`, `mvn package` | `FROM eclipse-temurin:21-jre` + `COPY --from=builder target/app.jar .` |
