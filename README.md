# FFE Terraform

Déploiement complet d’une stack Kubernetes via OpenTofu/Helm.
- Prod : cluster DOKS.
- Dev : cluster local (docker-desktop/minikube).
- Composants : Traefik, cert-manager/external-dns (prod), Velero (prod: Spaces, dev: MinIO), Postgres, MariaDB, apps (WordPress, n8n, CRM futur, Nextcloud, Mailu, Zot registry).

👉 Nouveaux arrivants : ce fichier est votre guide rapide.  
👉 Contexte complet humain : [CONTEXT_INFRA.md](CONTEXT_INFRA.md).  
👉 Rappels et règles IA : [docs/CONTEXT.md](docs/CONTEXT.md).  
👉 Blog post : [INITIAL_BLOG_POST.md](INITIAL_BLOG_POST.md).

## Prérequis
- `age` et `sops` installés.
- `tofu`/`helm`/`kubectl` installés, DO CLI (`doctl`) pour la prod.
- Exports attendus : `SOPS_AGE_KEY_FILE`, `SOPS_AGE_RECIPIENTS`, `APP_ENV=dev|prod`.

## Secrets (SOPS/age)
1. Générer la clé age : `bin/age-init.sh` puis exporter les variables.
2. Copier l’exemple : `cp secrets.tfvars.example secrets.tfvars` et remplir.
3. Chiffrer : `bin/sops-encrypt.sh secrets.tfvars secrets.tfvars.enc` (édition : `sops secrets.tfvars.enc`).
4. Utiliser le wrapper tofu (décrypte/nettoie auto) : `APP_ENV=... ./scripts/tofu-secrets.sh plan|apply`.

## Démarrage rapide
1) `export APP_ENV=dev` (ou `prod`) et `export TF_VAR_app_env=$APP_ENV` si besoin.  
2) `tofu init`.  
3) Prod seulement (cluster absent) : `APP_ENV=prod ./scripts/tofu-secrets.sh apply -target=module.doks-cluster`.  
4) Prod : récupérer le kubeconfig DO dans `./.kube/config` via `doctl kubernetes cluster kubeconfig save ...`.  
5) Déployer : `APP_ENV=... ./scripts/tofu-secrets.sh apply` (ou `plan`).  
6) Dev : vérifier la StorageClass (hostpath par défaut, overridable via `storage_class_name`).  
7) Si le cluster DOKS existe déjà et doit être conservé hors Terraform, retirer la ressource du state avant apply (`tofu state rm ...`).

## Domaines par défaut (`root_domain`)
- Prod : `root_domain_prod` (défaut `fullfrontend.be`)
- Dev : `root_domain_dev` (défaut `fullfrontend.kube`)
- FQDN dérivés uniquement du `root_domain` (pas d’override app) :  
  WordPress `<root_domain>` ; n8n `n8n.<root_domain>` + webhooks `webhook.<root_domain>` ; Nextcloud `cloud.<root_domain>` ; Mailu `mail.<root_domain>` ; Analytics `insights.<root_domain>` ; Registry `registry.<root_domain>`.

## Bonnes pratiques
- Pas de charts/images Bitnami.
- Un module dédié par app (namespace `apps/<app>`), ingress Traefik, credentials DB dans `postgres_app_credentials`/`mariadb_app_credentials`.
- Jamais de secrets en clair ; privilégier SOPS/age ou `TF_VAR_*`.
- Init Jobs Postgres/MariaDB créent DB/utilisateur en `IF NOT EXISTS` (recréés si manquant).

## TLS en dev
- cert-manager off. Options :  
  1) Cert local (`mkcert`) + secrets TLS par ingress (noms : `wordpress-tls`, `nextcloud-tls`, `mailu-tls`, `analytics-tls`, `n8n-tls`).  
  2) HTTP only (retirer les blocs TLS).  
  3) Proxy local qui termine TLS.

## Monitoring
- `kube-prometheus-stack` toggle : `enable_kube_prometheus_stack=true` (prod par défaut).
- Dashboards Grafana prêts à importer : [grafana/dashboards/](grafana/dashboards/) (cf. [grafana/dashboards/README.md](grafana/dashboards/README.md)).

## Besoin de creuser ?
- Vision détaillée infra/humaine : [CONTEXT_INFRA.md](CONTEXT_INFRA.md).  
- Règles et raccourcis pour l’IA : [docs/CONTEXT.md](docs/CONTEXT.md).

## Contribuer
- Issues/PR bienvenues. Pas de secrets en clair, pas d’images/charts Bitnami.
- Respecter le style existant (modules par app, commentaires multi-lignes si besoin).
- Les contributions sont acceptées sous la même licence (WTFPL).
- Voir aussi : [CONTRIBUTING.md](CONTRIBUTING.md) et [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Licence et avertissement
- Tout le dépôt (code, dashboards, schémas) est sous WTFPL (`LICENSE`).
- Aucune garantie ni support : auditez avant usage en prod.
- Les dépendances externes restent sous leurs propres licences.

## Sécurité
- Pour signaler une vulnérabilité, suivre les instructions de [SECURITY.md](SECURITY.md). Pas de secrets ni données sensibles dans les issues/PR.
