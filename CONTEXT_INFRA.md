# CONTEXTE DE L’INFRA

## Objectif
Migrer l’infrastructure existante vers un cluster Kubernetes DigitalOcean (DOKS) géré via OpenTofu/Terraform pour gagner en maîtrise des coûts, extensibilité, résilience et gestion du stateful.

## Références
- Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest  
- Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest  
- Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest

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
- Interdit : images/charts Bitnami (licence payante)

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
└── Namespace apps : wordpress, n8n, crm, nextcloud, mailu

## Organisation des modules
- `k8s-config` : uniquement infra/data (Traefik, cert-manager, external-dns, Velero, namespaces infra/data).
- Chaque application : module dédié qui crée son namespace dans `apps`.
- Domaine principal : variable unique `root_domain` (ex: fullfrontend.test) pour dériver les FQDN par défaut :
  - WordPress : `<root_domain>`
  - n8n : `n8n.<root_domain>` ; webhooks : `webhook.<root_domain>`
  - Nextcloud : `cloud.<root_domain>`
  - Mailu : `mail.<root_domain>` + MX/SPF/DKIM/DMARC
  - Overrides possibles via variables spécifiques (wp_host, n8n_host, n8n_webhook_host, etc.).
- Environnements : `APP_ENV=prod|dev` (`prod` = DOKS + cert-manager, kubeconfig généré dans `${path.root}/.kube/config` ; `dev` = cluster local (ex: docker-desktop), pas de cluster DOKS ni cert-manager, kubeconfig `~/.kube/config`).
- Velero : toujours déployé en prod (bucket DO Spaces créé automatiquement, planification quotidienne 03:00, rétention 30 jours) ; en dev, activable via `enable_velero` avec MinIO et stockage hostPath local (`./data/<velero_dev_bucket>`).
- Velero : toujours déployé en prod ; en dev, activable via `enable_velero`.

## Applications (règles et domaines)
- WordPress : MariaDB uniquement ; wp-content sur PVC ; plugin S3 optionnel ; ingress cert-manager ; FQDN par défaut `<root_domain>`.
- n8n : Postgres partagé ; stockage fichiers → S3 si besoin ; ingress ; FQDN par défaut `n8n.<root_domain>` + webhooks `webhook.<root_domain>`.
- CRM (à choisir) : Postgres prioritaire (MariaDB si incompatibilité) ; fichiers éventuels → S3 ; FQDN dérivé de `root_domain` ou override.
- Nextcloud : Postgres ; data sur PVC ; S3 en stockage externe optionnel ; FQDN par défaut `cloud.<root_domain>`.
- Mailu : chart officiel ; PV block ; DNS (DKIM/SPF/DMARC) via external-dns ; backups Spaces ; FQDN `mail.<root_domain>` + enregistrements MX/SPF/DKIM/DMARC.

## DNS
- Migration complète vers DNS DigitalOcean.
- external-dns gère automatiquement les enregistrements.
- Baisser les TTL pour les migrations ; mail : DKIM/SPF/DMARC gérés dans DO.

## Ajout d’une nouvelle application (cluster live)
- Créer un module dédié (namespace dans `apps`, ingress Traefik, chart non-Bitnami).
- Définir le FQDN via `root_domain` ou override.
- Ajouter les credentials DB dans `postgres_app_credentials` ou `mariadb_app_credentials` pour générer le secret applicatif.
- Important : les scripts d’init DB ne s’exécutent qu’au premier bootstrap des StatefulSets. Si Postgres/MariaDB tournent déjà, créer la DB et l’utilisateur manuellement (kubectl exec ou Job) avant de déployer l’app, avec les mêmes credentials que le secret.
- external-dns et cert-manager gèrent DNS/ACME dès que l’ingress est appliqué.
- Pour basculer dev/prod avec Terraform : `export APP_ENV=dev; export TF_VAR_app_env=$APP_ENV` (prod par défaut).

## Priorités de migration
1) Cluster DOKS + infra (Ingress, cert-manager, external-dns).  
2) Postgres (StatefulSet + backups).  
3) MariaDB (StatefulSet + backups si nécessaire).  
4) WordPress.  
5) n8n.  
6) Centralisation DNS DO.  
7) Nextcloud (remplacement Mailinabox partiel).  
8) Mailu (migration mail complète).
