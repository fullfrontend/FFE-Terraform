# FFE Terraform

Provision et déploiement complet d’une stack Kubernetes sur DigitalOcean (prod) ou sur un cluster local (dev, ex: docker-desktop) avec OpenTofu/Helm.

Pour le cadre global et les règles :
- Contexte humain : `CONTEXT_INFRA.md`
- Contexte IA : `docs/CONTEXT.md`

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
2. Créer/chiffrer `secrets.tfvars.enc` avec vos mots de passe (mêmes secrets pour dev/prod).
3. Choisir l’environnement : `export APP_ENV=dev` ou `APP_ENV=prod`.
4. `terraform init` puis `APP_ENV=... ./scripts/tofu-secrets.sh apply` (ou `plan`).
5. Vérifier la StorageClass en dev (`hostpath` par défaut, configurable via `storage_class_name`).
6. Ajuster domaines/creds dans `variable.tf` / tfvars chiffré.

## Domaines par défaut (`root_domain`)
- Prod : `fullfrontend.be` (variable `root_domain_prod`)
- Dev : `fullfrontend.kube` (variable `root_domain_dev`)
- WordPress : `<root_domain>`
- n8n : `n8n.<root_domain>` + `webhook.<root_domain>`
- Nextcloud : `cloud.<root_domain>`
- Mailu : `mail.<root_domain>` + MX/SPF/DKIM/DMARC
- Analytics (Vince) : `insights.<root_domain>` (choisi pour éviter les bloqueurs)
- Les FQDN sont dérivés uniquement de `root_domain` (pas d’override app par app).

## Bonnes pratiques
- Pas de charts/images Bitnami.
- Ajout d’app : module dédié (namespace `apps/<app>`), ingress Traefik, entrée DB dans `postgres_app_credentials`/`mariadb_app_credentials` (créer DB+user manuellement si DB déjà en place).
- Accès DB : `kubectl port-forward` ponctuel (Postgres `kubectl port-forward svc/postgres 5432:5432 -n data`, MariaDB `kubectl port-forward svc/mariadb 3306:3306 -n data`).
- Secrets : jamais en clair dans git ; utiliser SOPS/age ou variables d’environnement `TF_VAR_*` (secrets identiques en dev/prod).

### Mailu et multi-domaine
- Un seul host exposé suffit (ex: `mail.<root_domain>`) si les MX des autres domaines pointent vers ce host. Dans Mailu admin : ajouter les domaines (`he8us.be`, `perinatalite.be`, etc.) puis comptes/alias.
- DNS : MX des domaines supplémentaires vers `mail.<root_domain>`, SPF/DKIM/DMARC alignés sur ce host.
- Si tu veux exposer plusieurs FQDN (ex: `mail.he8us.be`), ajoute ces hosts dans l’ingress Mailu et assure-toi que le certificat TLS couvre ces SAN.

### Analytics (Vince)
- Sous-domaine par défaut : `insights.<root_domain>` (limite le blocage par les adblockers).
- Chart Helm officiel `vince` (repo `https://vinceanalytics.com/charts`), `baseURL=https://<host>`, domaines pré-ajoutés (`analytics_domains`, par défaut root_domain).
- Admin initial (user/pass) injecté via SOPS (secrets uniques pour dev/prod).

## Commentaire code
- Favoriser les commentaires multi-lignes au format :
  ```
  /*
      Your comment here
  */
  ```

## Backups Velero
- Prod : bucket DO Spaces auto-créé, backup quotidien 03:00, rétention 30 jours.
- Dev : MinIO + hostPath `./data/<cluster_name>` (git-ignoré), même planification, avec clés dédiées MinIO (pas les clés Spaces).
- TODO : générer une paire d’Access/Secret Keys Spaces dédiée à Velero via le panel DO (non gérable par Terraform), puis les mettre dans `secrets.tfvars` chiffré.

## TLS en dev (cluster local)
- cert-manager est désactivé en dev. Options :
  1) Générer une CA locale immuable + wildcard : `mkcert -install` puis `mkcert "*.docker.internal"` (ou `*.<root_domain>` si résolu en local) ; créer un secret TLS par ingress, ex : `kubectl create secret tls wordpress-tls --cert=fullchain.pem --key=privkey.pem -n apps`.
  2) Accepter du HTTP en dev (supprimer les blocs TLS des ingress).
  3) Utiliser un proxy local qui termine TLS avec le certificat généré (traefik local).
Choisis une approche et aligne les noms de secrets avec ceux attendus par les ingress (`wordpress-tls`, `nextcloud-tls`, `mailu-tls`, `analytics-tls`, `n8n-tls` si besoin).

## Documentation
- Schéma prod : `docs/architecture-prod.png`
- DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest  
- Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest  
- Helm : https://search.opentofu.org/provider/hashicorp/helm/latest  
- age : https://github.com/FiloSottile/age  
- sops : https://github.com/getsops/sops

## Dev (minikube)
- Commande de création minikube utilisée en dev :  
  `minikube delete && minikube start --driver=docker && minikube addons enable ingress && minikube addons enable ingress-dns && minikube addons enable metrics-server && minikube dashboard`
