Objectif du projet

Migrer toute l’infrastructure actuelle vers un cluster Kubernetes DigitalOcean (DOKS) entièrement piloté via OpenTofu (Terraform).
But : auto-hébergement, maîtrise des coûts, cohérence, extensibilité, et contrôle total sur le stateful.

⸻

Références documentation
•	Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest
•	Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest
•	Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest

⸻

Composants actuels (à migrer)
•	WordPress (site principal)
•	Mautic → sera remplacé
•	n8n (automatisations)
•	CRM (solution à définir)
•	Nextcloud (fichiers, CalDAV, CardDAV)
•	Mail (Mailinabox aujourd’hui → Mailu demain)
•	DNS actuellement géré par Mailinabox

⸻

Stack cible (plateforme Kubernetes)

Infrastructure
•	Cluster : Kubernetes DigitalOcean (DOKS)
•	Provisioning : OpenTofu (Terraform)
•	Ingress : Traefik
•	Certificats : cert-manager (Let’s Encrypt)
•	DNS : external-dns (provider DigitalOcean)
•	Storage POSIX : DigitalOcean Block Storage via CSI driver (PVC)
•	Storage Object : DigitalOcean Spaces (équivalent S3)
•	Backups : Velero (backups seulement) vers Spaces

Règles de stockage
1.	Do Block Storage = POSIX
À utiliser pour tout ce qui est stateful :
•	Bases de données (Postgres/MariaDB)
•	Nextcloud data (base)
•	WordPress wp-content si non déporté
•	Mailu (maildir, queue, config)
2.	Spaces (S3) = objet
Usage :
•	Médias WordPress (via plugin S3)
•	Stockage externe Nextcloud (optionnel)
•	Backups DB
•	Backups Mailu
•	Assets statiques
Ne pas utiliser comme FS principal via CSI pour DB ou Nextcloud.
Interdit : images/charts Bitnami (licence payante).

⸻

Base de données

Pas de managed DB.
→ Le cluster utilise Postgres (recommandé) ou MariaDB, déployé comme StatefulSet K8S, avec :
•	1 StatefulSet
•	1 PVC block storage
•	Backups en CronJob → Spaces
•	Restauration testée régulièrement

⸻

Applications à déployer

WordPress
•	Nginx + PHP-FPM
•	DB MariaDB uniquement
•	wp-content → PVC ou plugin S3
•	Exposé via Ingress + cert-manager

n8n
•	DB Postgres (DB séparée dans le même cluster)
•	Stockage fichiers secondaire → S3 si besoin
•	Accès via Ingress

CRM (auto-hébergé)
•	DB à définir (Postgres prioritaire ; MariaDB si l’app ne supporte pas Postgres)
•	Stockage éventuel → S3

Nextcloud
•	DB Postgres
•	data → PVC block
•	Support possible du backend S3 en mode externe

Mailu (Kubernetes)
•	Helm chart officiel
•	PV block pour maildir/config
•	Backups → Spaces
•	SPF/DKIM/DMARC configurés via DNS DO

⸻

DNS
•	Migration complète vers DigitalOcean DNS
•	Gestion automatique via external-dns
•	TTL bas pour migration
•	Étapes mail : conserver DKIM/SPF/DMARC coherents

⸻

Architecture recommandée (simplifiée)


Kubernetes (DOKS)
├── Namespace infra
│    ├── ingress-controller
│    ├── cert-manager
│    ├── external-dns
│    ├── monitoring/logging
│    ├── velero/backups
│
├── Namespace data
│    ├── postgres (statefulset + pvc)
│    ├── MariaDB (statefulset + pvc)
│
├── Namespace apps
│    ├── wordpress
│    ├── n8n
│    ├── crm
│    ├── nextcloud
│    ├── mailu

Organisation modules
•	module k8s-config → ne gère que l’infra et data (Traefik, cert-manager, external-dns, Velero, namespaces infra/data).
•	chaque application → module dédié qui crée son namespace dans “apps”.
•	Domaine principal défini à un seul endroit (`root_domain`, ex: example.com) pour dériver les FQDN des apps.



⸻

Ordre de migration recommandé
1.	Déploiement cluster + infra (Ingress, certs, DNS, storage)
2.	Postgres (statefulset + backups)
3.	MariaDB (statefulset + backups si nécessaire)
4.	WordPress
5.	n8n
6.	Migration DNS vers DO
7.	Nextcloud
8.	Mailu

⸻

Règles pour l’IA (important)
•	Toujours proposer des solutions 100% auto-hébergées.
•	Ne jamais recommander une base de données managée.
•	Utiliser DigitalOcean, Kubernetes, OpenTofu, Helm, PVC block, Spaces S3 uniquement.
•	Séparer stateful (PVC) et objet (Spaces).
•	Proposer des solutions robustes, simples et extensibles.
•	Préférer une architecture modulaire (namespace : infra, data, apps).
•	Toute nouvelle app → chart Helm + DB Postgres en priorité ; MariaDB uniquement si l’app ne supporte pas Postgres (ex : WordPress).
•	Bannir les images/charts Bitnami (privilégier charts upstream/officiels).
