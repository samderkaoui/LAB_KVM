# Doc

## Pourquoi 2 roles séparé dans ma collection :

**Le problème avec le `when: master / when: worker` dans un seul rôle**

```yaml
# tasks/main.yml — à éviter
- include_tasks: master.yml
  when: inventory_hostname in groups['master']

- include_tasks: worker.yml
  when: inventory_hostname in groups['workers']
```

Ça fonctionne, mais tu crées un rôle qui **sait trop de choses** sur ton inventaire. C'est fragile : si tu renommes ton groupe, tu dois fouiller dans le rôle. Et le rôle n'est plus réutilisable hors de ce contexte précis.

---

**Avec 2 rôles, ton playbook devient la logique d'orchestration**

```yaml
# site.yml
- hosts: master
  roles:
    - k3s_master

- hosts: workers
  roles:
    - k3s_worker
```

C'est lisible, immédiatement compréhensible, et chaque rôle est **cohérent et autonome**.

---

**Règle générale à retenir**

> Un rôle = une responsabilité claire, exécutable indépendamment.

Un rôle `k3s` qui gère à la fois le master et les workers a **deux responsabilités** — c'est le signe qu'il faut splitter.

---

**La seule exception acceptable**

Un rôle unique avec `when` peut se justifier si les tâches communes représentent **80%+ du contenu** (ex: install du binaire, configuration réseau commune, etc.) et que les divergences master/worker sont vraiment minimes. Dans ce cas, tu peux faire :

```
roles/k3s/
├── tasks/
│   ├── main.yml       # tâches communes
│   ├── master.yml     # spécifique master
│   └── worker.yml     # spécifique worker
```

Mais pour k3s, la différence master/worker est suffisamment significative (token bootstrap, init du cluster, kubeconfig...) pour justifier 2 rôles distincts.

----

## `requirements.yml` et `meta/main.yml` — collections et dépendances

### `requirements.yml`

Installe les collections Ansible nécessaires au bon fonctionnement de ta propre collection.
À exécuter une seule fois avant de lancer le playbook :

```bash
ansible-galaxy collection install -r requirements.yml
```

### `meta/main.yml` — deux clés distinctes

**`collections`** — raccourcis de nommage pour les modules utilisés dans les tasks.

Sans `collections`, tu dois écrire le nom complet du module :
```yaml
- community.general.ufw: ...
```
Avec `collections` déclaré dans `meta/main.yml` :
```yaml
collections:
  - community.general
  - kubernetes.core
```
Tu peux écrire directement :
```yaml
- ufw: ...
```

---

**`dependencies`** — rôles qui s'exécutent **avant** ce rôle (pas des collections, des rôles).

```yaml
dependencies:
  - labkvm.k3scollection.common
```

> Exemple : le rôle `common` installe `curl` et configure le système avant que `master_cluster_k3s` tourne.

Les dépendances garantissent un ordre d'exécution déclaratif, sans avoir à les appeler explicitement dans le playbook.
