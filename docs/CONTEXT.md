Objectif
Migrer toute l’infrastructure vers un cluster Kubernetes DigitalOcean (DOKS) piloté via OpenTofu (Terraform) pour l’auto-hébergement, la maîtrise des coûts, la cohérence et le contrôle du stateful.

Références
- Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest
- Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest
- Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest

Plateforme cible
- Ingress : Traefik
- Certificats : cert-manager (Let’s Encrypt)
- DNS : external-dns (DigitalOcean)
- Stockage POSIX : DigitalOcean Block Storage (PVC)
- Stockage objet : DigitalOcean Spaces (S3)
- Backups : Velero (backups uniquement) vers Spaces
- Interdit : images/charts Bitnami (licence payante)

Règles de stockage
1) Block storage (PVC) pour tout le stateful : Postgres/MariaDB, data Nextcloud, wp-content, Mailu (maildir/queue/config).  
2) Spaces (S3) pour objets : médias WordPress, backups DB/Nextcloud/Mailu, stockage externe Nextcloud optionnel.  
Ne pas utiliser Spaces comme FS principal via CSI pour DB/Nextcloud.

Base de données
- Pas de DB managée.
- StatefulSets Postgres prioritaires ; MariaDB seulement si l’app ne supporte pas Postgres.
- 1 StatefulSet + 1 PVC + backups vers Spaces + restauration testée.

Architecture cible
Kubernetes (DOKS)  
├── infra : ingress-controller, cert-manager, external-dns, monitoring/logging, velero/backups  
├── data : postgres (statefulset+pvc), mariadb (statefulset+pvc)  
└── apps : wordpress, n8n, crm, nextcloud, mailu

Organisation des modules
- `k8s-config` : infra + data (Traefik, cert-manager, external-dns, Velero, namespaces infra/data).
- Chaque application : module dédié et namespace dans `apps`.
- Domaine principal unique `root_domain` (ex: fullfrontend.test) pour dériver les FQDN par défaut :
  - WordPress : `<root_domain>`
  - n8n : `n8n.<root_domain>` ; webhooks : `webhook.<root_domain>`
  - Nextcloud : `cloud.<root_domain>`
  - Mailu : `mail.<root_domain>` + MX/SPF/DKIM/DMARC
  - Overrides possibles via variables par app.

Applications cibles
- WordPress : DB MariaDB, wp-content sur PVC, plugin S3 optionnel, ingress cert-manager, FQDN défaut `<root_domain>`.
- n8n : DB Postgres partagée, stockage S3 optionnel, ingress, FQDN défaut `n8n.<root_domain>` + webhooks `webhook.<root_domain>`.
- CRM (à choisir) : DB Postgres prioritaire (MariaDB si incompatible), fichiers éventuels S3, FQDN dérivé ou override.
- Nextcloud : DB Postgres, data sur PVC, S3 externe optionnel, FQDN défaut `cloud.<root_domain>`.
- Mailu : chart officiel, PV block, DNS DKIM/SPF/DMARC via external-dns, backups Spaces, FQDN `mail.<root_domain>` + enregistrements mail.

Ajout d’une application sur cluster live
- Créer un module dédié (namespace `apps/<app>`, ingress Traefik, chart non-Bitnami).
- Définir le FQDN via `root_domain` ou override.
- Ajouter l’entrée dans `postgres_app_credentials` ou `mariadb_app_credentials` pour générer le secret DB.
- Les scripts d’init DB ne rejouent pas : si Postgres/MariaDB sont déjà en production, créer DB+user manuellement (kubectl exec ou Job) avec les mêmes credentials avant le déploiement.
- external-dns et cert-manager gèrent DNS/ACME dès que l’ingress est appliqué.

Ordre de migration recommandé
1) Cluster + infra (Ingress, certs, DNS, storage)  
2) Postgres (statefulset + backups)  
3) MariaDB (statefulset + backups si nécessaire)  
4) WordPress  
5) n8n  
6) Migration DNS vers DO  
7) Nextcloud  
8) Mailu

Règles pour l’IA (important)
- Toujours proposer des solutions 100% auto-hébergées.
- Ne jamais recommander une base de données managée.
- Utiliser DigitalOcean, Kubernetes, OpenTofu, Helm, PVC block, Spaces S3 uniquement.
- Séparer stateful (PVC) et objet (Spaces).
- Proposer des solutions robustes, simples, extensibles.
- Architecture modulaire (namespace : infra, data, apps).
- Toute nouvelle app → chart Helm + DB Postgres en priorité ; MariaDB seulement si l’app ne supporte pas Postgres (ex : WordPress).
- Bannir les images/charts Bitnami (privilégier charts upstream/officiels).
