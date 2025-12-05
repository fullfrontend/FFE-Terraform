# CONTEXTE DE L’INFRA

## Objectif
Migrer l’infrastructure existante vers un cluster Kubernetes DigitalOcean (DOKS) géré via OpenTofu/Terraform pour gagner en maîtrise des coûts, extensibilité, résilience et gestion du stateful.

## Références
- Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest  
- Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest  
- Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest
- Schéma prod : `docs/architecture-prod.png`

## Stack actuelle (avant migration)
- Serveur cloud (Ubuntu 22.04) : Mailinabox (mail + DNS + CalDAV + CardDAV via Nextcloud).
- Serveur prod Docker (Ubuntu 24.04) : WordPress + Mautic + Traefik.

## Stack cible (plateforme)
- Ingress : Traefik
- Certificats : cert-manager (Let’s Encrypt)
- DNS : external-dns (DigitalOcean)
- Stockage POSIX : CSI DigitalOcean Block Storage (PVC)
- Stockage objet : DigitalOcean Spaces (S3)
- Backups : Velero (backups uniquement vers Spaces)
- Registry privé : Zot exposé via ingress (`registry.<root_domain>`)
- Interdit : images/charts Bitnami (licence payante)

## Secrets (SOPS/age)
- Clé age générée via `bin/age-init.sh`; exporter `SOPS_AGE_KEY_FILE` et `SOPS_AGE_RECIPIENTS`.
- Générer le fichier clair depuis l’exemple : `cp secrets.tfvars.example secrets.tfvars` puis compléter et chiffrer avec `bin/sops-encrypt.sh secrets.tfvars secrets.tfvars.enc` (policy `sops.yaml`).
- Wrapper tofu : `APP_ENV=... ./scripts/tofu-secrets.sh plan|apply` (décrypte en `.secrets.auto.tfvars`, nettoie).
- Jamais de secrets en clair dans git (tfvars clairs exclus, `.secrets.auto.tfvars` ignoré).

## Stockage
1) Block Storage (PVC) pour tout le stateful : Postgres/MariaDB, Nextcloud data, wp-content, Mailu (maildir/queue/config).  
2) Spaces (S3) pour objets : médias WordPress, backups DB/Nextcloud/Mailu, stockage externe Nextcloud optionnel.  
Ne pas utiliser Spaces comme volume POSIX principal pour DB/Nextcloud.

## Base de données
- Pas de managed DB. StatefulSets auto-hébergés.
- Postgres prioritaire ; MariaDB seulement si l’app ne supporte pas Postgres.
- 1 StatefulSet + 1 PVC + backups vers Spaces + vérif de restauration.

## Architecture cible
Kubernetes (DOKS)  
├── Namespace infra : ingress-controller, cert-manager, external-dns, monitoring/logging, velero/backups  
├── Namespace data : postgres (statefulset + pvc), mariadb (statefulset + pvc)  
├── Namespace metrics : monitoring/alerting (kube-prometheus-stack)  
└── Namespace apps : wordpress, n8n, crm, nextcloud, mailu, registry

## Organisation des modules
- `k8s-config` : uniquement infra/data (Traefik, cert-manager, external-dns, Velero, namespaces infra/data).
- Chaque application : module dédié qui crée son namespace dans `apps`.
- Domaine principal : dérivé automatiquement de l’environnement (prod: `root_domain_prod`, dev: `root_domain_dev` ; défauts : `fullfrontend.be` / `fullfrontend.kube`) pour les FQDN par défaut :
  - WordPress : `<root_domain>`
  - n8n : `n8n.<root_domain>` ; webhooks : `webhook.<root_domain>`
  - Nextcloud : `cloud.<root_domain>`
  - Mailu : `mail.<root_domain>` + MX/SPF/DKIM/DMARC
  - Analytics : `insights.<root_domain>`
  - Registry : `registry.<root_domain>`
  - FQDN non override : dérivés uniquement de `root_domain`.
- Environnements : `APP_ENV=prod|dev` (`prod` = DOKS + cert-manager, kubeconfig à récupérer puis écrire dans `${path.root}/.kube/config` via `doctl kubernetes cluster kubeconfig save ...`; `dev` = cluster local (ex: docker-desktop), pas de cluster DOKS ni cert-manager, kubeconfig `~/.kube/config`).
- Velero : toujours déployé (prod → Spaces, dev → MinIO hostPath), planification quotidienne 03:00, rétention 30 jours (clés DO Spaces nécessaires pour créer le bucket). Chaque app peut ajouter son propre `Schedule` via Terraform (ex: WordPress crée `velero.io/Schedule wordpress-daily` dans `infra` qui capture son namespace/PVC).
- Velero : toujours déployé en prod ; en dev, activé avec MinIO hostPath.

## Applications (règles et domaines)
- WordPress : MariaDB uniquement ; wp-content sur PVC ; plugin S3 optionnel ; ingress cert-manager ; FQDN par défaut `<root_domain>`.
- n8n : Postgres partagé ; stockage fichiers → S3 si besoin ; ingress ; FQDN par défaut `n8n.<root_domain>` + webhooks `webhook.<root_domain>`.
- CRM (à choisir) : Postgres prioritaire (MariaDB si incompatibilité) ; fichiers éventuels → S3 ; FQDN dérivé de `root_domain`.
- Nextcloud : Postgres ; data sur PVC ; S3 en stockage externe optionnel ; FQDN `cloud.<root_domain>`.
- Mailu : chart officiel ; PV block ; DNS (DKIM/SPF/DMARC) via external-dns ; backups Spaces ; FQDN `mail.<root_domain>` + enregistrements MX/SPF/DKIM/DMARC.
- Registry (Zot) : ingress `registry.<root_domain>`, PVC dédié, htpasswd optionnel.

## DNS
- Migration complète vers DNS DigitalOcean.
- external-dns gère automatiquement les enregistrements.
- Baisser les TTL pour les migrations ; mail : DKIM/SPF/DMARC gérés dans DO.

## Ajout d’une nouvelle application (cluster live)
- Créer un module dédié (namespace dans `apps`, ingress Traefik, chart non-Bitnami).
- Définir le FQDN via `root_domain` (pas d’override par app).
- Ajouter les credentials DB dans `postgres_app_credentials` ou `mariadb_app_credentials` pour générer le secret applicatif.
- Important : les scripts d’init DB ne s’exécutent qu’au premier bootstrap des StatefulSets. Si Postgres/MariaDB tournent déjà, créer la DB et l’utilisateur manuellement (kubectl exec ou Job) avant de déployer l’app, avec les mêmes credentials que le secret.
- external-dns et cert-manager gèrent DNS/ACME dès que l’ingress est appliqué.
- Pour basculer dev/prod avec Terraform : `export APP_ENV=dev; export TF_VAR_app_env=$APP_ENV` (prod par défaut).
- Init Jobs : Postgres/MariaDB sont créés via un Job (TTL 120s) qui exécute `IF NOT EXISTS` sur DB/utilisateur. Si le Job est garbage collecté ou si de nouvelles apps sont ajoutées, un apply recrée le Job et ajoute uniquement les bases manquantes.

## Priorités de migration
1) Cluster DOKS + infra (Ingress, cert-manager, external-dns).  
2) Postgres (StatefulSet + backups).  
3) MariaDB (StatefulSet + backups si nécessaire).  
4) WordPress.  
5) n8n.  
6) Centralisation DNS DO.  
7) Nextcloud (remplacement Mailinabox partiel).  
8) Mailu (migration mail complète).
