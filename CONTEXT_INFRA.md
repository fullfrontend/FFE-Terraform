# CONTEXTE DE L’INFRA (humain)

Public : personnes qui veulent comprendre l’architecture et les règles de la plateforme (au-delà du quickstart du README).

## Objectif et périmètre
- Migrer vers Kubernetes DigitalOcean (DOKS) géré via OpenTofu/Helm pour maîtriser coûts, résilience et état.
- Prod : cluster DOKS. Dev : cluster local (docker-desktop/minikube). Pas de bases managées.
- Diagramme prod : `docs/architecture-prod.png`. Blog post : `INITIAL_BLOG_POST.md`.

## Architecture cible
- Namespaces :  
  - `infra` (Traefik, cert-manager, external-dns, Velero)  
  - `data` (Postgres, MariaDB)  
  - `metrics` (kube-prometheus-stack)  
  - `apps/<app>` (wordpress, n8n, crm, nextcloud WIP, analytics, registry)
- Ingress : Traefik en prod, nginx via minikube en dev. WAF global (ModSecurity + OWASP CRS via Traefik, prod). Certificats : cert-manager (Let’s Encrypt) en prod. DNS : external-dns (DO).
- Backups : Velero (prod → DO Spaces, dev → MinIO hostPath). Planification 03:00, rétention 30 jours.
- Registry : Zot exposé via ingress `registry.<root_domain>`.
- Interdit : images/charts Bitnami.

## Environnements
- Variables : `APP_ENV=prod|dev`, `TF_VAR_app_env` optionnel pour aligner Terraform.
- Prod : kubeconfig dans `${path.root}/.kube/config` via `doctl ... kubeconfig save ...`. cert-manager + external-dns actifs.
- Dev : kubeconfig `~/.kube/config` (docker-desktop/minikube). cert-manager/external-dns désactivés. Velero utilise MinIO local (`./data/<cluster_name>`).

## Secrets (SOPS/age)
- Générer la clé age (`bin/age-init.sh`), exporter `SOPS_AGE_KEY_FILE` et `SOPS_AGE_RECIPIENTS`.
- Copier/compléter `secrets.tfvars` depuis l’exemple, chiffrer en `secrets.tfvars.enc` via `bin/sops-encrypt.sh ...`.
- Wrapper tofu : `APP_ENV=... ./scripts/tofu-secrets.sh plan|apply` (décrypte `.secrets.auto.tfvars`, nettoie). Jamais de secrets en clair (tfvars clairs hors git, `.secrets.auto.tfvars` ignoré).

## Stockage
1) Block storage (PVC) pour tout le stateful : Postgres/MariaDB, Nextcloud data, wp-content.  
2) Objet (DO Spaces ou MinIO) pour médias, backups DB/Nextcloud, stockage externe optionnel Nextcloud.  
Ne jamais monter Spaces comme volume POSIX principal.

## Bases de données
- Auto-hébergées (pas de managed DB). Postgres prioritaire ; MariaDB seulement si l’app l’exige (WordPress).
- 1 StatefulSet + 1 PVC par SGBD. Backups vers Spaces/MinIO.
- Init Jobs (TTL 120s) créent DB/utilisateur par app en `IF NOT EXISTS`. Si le Job disparaît ou qu’une app est ajoutée, un apply recrée uniquement les bases manquantes.

## Domaines et applications
- Domaine par environnement (défauts : prod `fullfrontend.be`, dev `fullfrontend.kube`). Pas d’override app.
- FQDN : WordPress `<root_domain>` ; n8n `n8n.<root_domain>` + webhooks `webhook.<root_domain>` ; Nextcloud `cloud.<root_domain>` (WIP) ; Analytics `insights.<root_domain>` ; Sentry `sentry.<root_domain>` ; Registry `registry.<root_domain>`.
- Règles app :  
  - WordPress : MariaDB + PVC wp-content, plugin S3 optionnel, ingress cert-manager en prod.  
  - n8n : Postgres partagé, S3 optionnel, ingress.  
  - CRM (à choisir) : Postgres par défaut, S3 si fichiers.  
  - Nextcloud : Postgres + PVC, S3 externe optionnel, WIP.  
  - Analytics (Vince) : ingress dédié, admin bootstrap Helm, PVC data.  
  - Registry (Zot) : ingress dédié, PVC, htpasswd optionnel.

## DNS
- Migration DNS vers DigitalOcean ; external-dns gère les enregistrements.
- Mail : MX/SPF/DKIM/DMARC gérés dans DO ; réduire les TTL en phase de migration.

## Ajout d’une application (cluster live)
- Créer un module dédié (namespace `apps/<app>`), ingress Traefik, chart non-Bitnami.
- Ajouter les credentials DB dans `postgres_app_credentials` ou `mariadb_app_credentials` (secret généré). Si la DB tourne déjà, créer DB/user manuellement avant déploiement avec les mêmes creds.
- Les FQDN restent dérivés de `root_domain` (pas d’override).

## Priorités de migration
1) Cluster DOKS + infra (Ingress, cert-manager, external-dns)  
2) Postgres (stateful + backups)  
3) MariaDB (si nécessaire)  
4) WordPress  
5) n8n  
6) DNS DigitalOcean  
7) Nextcloud

## Références utiles
- Providers OpenTofu : DigitalOcean / Kubernetes / Helm.  
- Diagramme : `docs/architecture-prod.png`.  
- Blog post : `INITIAL_BLOG_POST.md`.
