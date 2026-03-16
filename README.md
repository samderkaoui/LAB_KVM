- Créer le fichier local.pkrvars.hcl

```hcl
ssh_username  = "lab"
ssh_password  = "lab"
iso_checksum  = "sha256:0b813535dd76f2ea96eff908c65e8521512c92a0631fd41c95756ffd7d4896dc" # obtenue avec
# curl -s https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS | grep netinst

```

- Init du projet a la racine des dossiers ( Debian / Almalinux ):
```bash
packer init .
```

-Build avec les variables locales:
```bash
packer build -var-file=local.pkrvars.hcl debian13-base.pkr.hcl
```
