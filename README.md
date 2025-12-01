# FFE Terraform

Provision et déploiement complet d’une stack Kubernetes sur DigitalOcean (prod) ou sur un cluster local (dev, ex: docker-desktop) avec OpenTofu/Helm.

## Vue d’ensemble
- Infra : Traefik, external-dns (prod), cert-manager (prod), Velero (prod: Spaces, dev: MinIO).
- Données : Postgres, MariaDB (PVC bloc).
- Apps : WordPress (MariaDB), n8n (Postgres), CRM futur, Nextcloud, Mailu.
- Stockage : bloc (PVC) vs objet (Spaces/MinIO).

## Environnements
- Prod (`APP_ENV=prod`) : cluster DOKS, kubeconfig `${path.root}/.kube/config`, cert-manager + external-dns actifs, Velero vers DO Spaces (bucket auto-créé).
- Dev (`APP_ENV=dev`) : cluster local (`~/.kube/config`, ex: docker-desktop), cert-manager/external-dns désactivés, Velero actif avec MinIO (`./data/<cluster_name>-velero`).

## Secrets (SOPS/age)
1. Installer age et sops :  
   - age : https://github.com/FiloSottile/age#installation  
   - sops : https://github.com/getsops/sops#installation
2. Générer une clé age : `bin/age-init.sh` puis exporter `SOPS_AGE_KEY_FILE` et `SOPS_AGE_RECIPIENTS` (local + CI).
3. Chiffrer vos tfvars : `bin/sops-encrypt.sh secrets.tfvars secrets.tfvars.enc` (ou `sops secrets.tfvars.enc` pour éditer).
4. Exécuter tofu via le wrapper (décrypte en `.secrets.auto.tfvars` puis nettoie) :  
   `APP_ENV=dev ./scripts/tofu-secrets.sh plan|apply`

## Process de démarrage
1. Installer age/sops, générer la clé age (`bin/age-init.sh`), exporter `SOPS_AGE_KEY_FILE` et `SOPS_AGE_RECIPIENTS`.
2. Créer/chiffrer `secrets.tfvars.enc` avec vos mots de passe (dev/prod).
3. Choisir l’environnement : `export APP_ENV=dev` ou `APP_ENV=prod`.
4. `terraform init` puis `APP_ENV=... ./scripts/tofu-secrets.sh apply` (ou `plan`).
5. Vérifier la StorageClass en dev (`hostpath` par défaut, configurable via `storage_class_name`).
6. Ajuster domaines/creds dans `variable.tf` / tfvars chiffré.

## Domaines par défaut (`root_domain`)
- WordPress : `<root_domain>`
- n8n : `n8n.<root_domain>` + `webhook.<root_domain>`
- Nextcloud : `cloud.<root_domain>`
- Mailu : `mail.<root_domain>` + MX/SPF/DKIM/DMARC

## Bonnes pratiques
- Pas de charts/images Bitnami.
- Ajout d’app : module dédié (namespace `apps/<app>`), ingress Traefik, entrée DB dans `postgres_app_credentials`/`mariadb_app_credentials` (créer DB+user manuellement si DB déjà en place).
- Accès DB : `kubectl port-forward` ponctuel (Postgres `kubectl port-forward svc/postgres 5432:5432 -n data`, MariaDB `kubectl port-forward svc/mariadb 3306:3306 -n data`).
- Secrets : jamais en clair dans git ; utiliser SOPS/age ou `TF_VAR_*_dev` / `TF_VAR_*_prod`.

### Mailu et multi-domaine
- Un seul host exposé suffit (ex: `mail.<root_domain>`) si les MX des autres domaines pointent vers ce host. Dans Mailu admin : ajouter les domaines (`he8us.be`, `perinatalite.be`, etc.) puis comptes/alias.
- DNS : MX des domaines supplémentaires vers `mail.<root_domain>`, SPF/DKIM/DMARC alignés sur ce host.
- Si tu veux exposer plusieurs FQDN (ex: `mail.he8us.be`), ajoute ces hosts dans l’ingress Mailu et assure-toi que le certificat TLS couvre ces SAN.

## Backups Velero
- Prod : bucket DO Spaces auto-créé, backup quotidien 03:00, rétention 30 jours.
- Dev : MinIO + hostPath `./data/<cluster_name>-velero` (git-ignoré), même planification.

## Documentation
- DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest  
- Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest  
- Helm : https://search.opentofu.org/provider/hashicorp/helm/latest  
- age : https://github.com/FiloSottile/age  
- sops : https://github.com/getsops/sops
