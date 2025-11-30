# CONTEXTE DE L’INFRA

Objectif global

Migrer l’infrastructure existante vers un cluster Kubernetes DigitalOcean (DOKS), entièrement géré via OpenTofu (Terraform).
But : auto-hébergement, maîtrise des coûts, extensibilité, résilience, gestion propre du stateful.

⸻

Références documentation
•	Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest
•	Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest
•	Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest

⸻

Stack actuelle (avant migration)
•	Serveur cloud (Ubuntu 22.04) : Mailinabox (mail + DNS + CalDAV + CardDAV via Nextcloud).
•	Serveur prod Docker (Ubuntu 24.04) : WordPress + Mautic + Traefik.

⸻

Stack cible (Kubernetes)

Cluster Kubernetes DigitalOcean, provisionné via OpenTofu.

Composants “plateforme”
•	Ingress Controller (Traefik)
•	cert-manager (certificats Let’s Encrypt)
•	external-dns (DNS automatisé avec DigitalOcean)
•	CSI DigitalOcean Block Storage (storage POSIX pour PVC)
•	Velero (backups seulement, vers Spaces)

Stockage

Important : deux niveaux de storage
1.	Volumes Block DO (PVC) → pour tout ce qui nécessite POSIX :
•	Postgres/MariaDB (bases WP, n8n, CRM, Nextcloud, Mailu)
•	Nextcloud data (base)
•	WordPress wp-content (si non déporté)
•	Mailu (maildir, queue, config)
2.	Spaces DO (Object Storage S3) → pour assets et backups via API :
•	Médias WordPress (via plugin S3)
•	Backups DB
•	Backups Nextcloud
•	Backups Mailu
•	Stockage externe Nextcloud (optionnel)

Ne pas utiliser Spaces comme volume POSIX principal pour DB ou Nextcloud.
Interdit : images/charts Bitnami (licence payante).

⸻

Applications à déployer dans K8S

1. WordPress
   •	PHP-FPM + Nginx
   •	DB (MariaDB uniquement)
   •	wp-content sur PVC
   •	Médias → plugin S3 vers Spaces (optionnel)
   •	Ingress + cert-manager

2. n8n
   •	DB Postgres (cluster partagé)
   •	Stockage fichiers → S3 si besoin
   •	Exposé via Ingress

3. CRM (auto-hébergé, choix futur)
   •	DB à définir (Postgres prioritaire ; MariaDB si l’app ne supporte pas Postgres)
   •	Fichiers éventuels → S3

4. Nextcloud
   •	DB Postgres
   •	data sur PVC
   •	Stockage S3 comme backend externe possible

5. Mailu (recommandé)
   •	Helm chart officiel
   •	PV block pour maildir
   •	DKIM/SPF/DMARC via external-dns
   •	Backups → Spaces

⸻

DNS
•	Migration complète vers DNS DigitalOcean
•	Gestion automatisée des enregistrements via external-dns
•	Baisse des TTL pour migrations
•	Mail : gérer DKIM/SPF/DMARC dans DO

⸻

Base de données

Pas de managed DB → auto-hébergement via StatefulSet :
•	Postgres prioritaire (dès que possible par l'app), MariaDB uniquement si l'app ne supporte pas Postgres
•	1 StatefulSet, 1 PVC Block Storage
•	Backups vers Spaces
•	Monitoring + job de vérification de restauration

⸻

Architecture recommandée (résumé)

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
•	module k8s-config → provisionne seulement l’“infra” et “data” (Traefik, cert-manager, external-dns, Velero, namespaces infra/data).
•	chaque application dispose de son propre module dédié, qui crée son namespace dans “apps”.
•	Domaine principal configurable en une seule variable (`root_domain`, ex: example.com) pour dériver les FQDN des apps.


⸻

Priorités de migration (ordre logique)
1.	Cluster DOKS + infrastructure plateforme (Ingress, cert-manager, external-dns).
2.	Postgres (StatefulSet + backups).
3.	MariaDB (StatefulSet + backups si nécessaire).
4.	WordPress.
5.	n8n.
6.	Centralisation DNS DO.
7.	Nextcloud (remplacement Mailinabox partiel).
8.	Mailu (migration mail complète).
