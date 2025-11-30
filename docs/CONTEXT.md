Objectif  
Migrer l’infra vers Kubernetes (DOKS en prod, cluster local en dev, ex: docker-desktop) géré via OpenTofu, en séparant bloc/objet et avec backups quotidiens.

Références  
- DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest  
- Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest  
- Helm : https://search.opentofu.org/provider/hashicorp/helm/latest  
- Minikube : https://registry.terraform.io/providers/scott-the-programmer/minikube/latest/docs (non utilisé par défaut en dev si cluster local dispo)

Plateforme  
- Ingress : Traefik  
- Certificats : cert-manager (prod)  
- DNS : external-dns (DO)  
- Stockage : PVC bloc (DO CSI) + objet (Spaces/MinIO)  
- Backups : Velero (quotidien 03:00, rétention 30 jours)  
- Interdit : charts/images Bitnami

Environnements  
- prod (`APP_ENV=prod`) : cluster DOKS, kubeconfig `${path.root}/.kube/config`, cert-manager on, Velero vers DO Spaces (bucket auto-créé).  
- dev (`APP_ENV=dev`) : cluster local existant (ex: docker-desktop) via kubeconfig `~/.kube/config`, cert-manager off, Velero optionnel via MinIO + hostPath `./data/<velero_dev_bucket>`.  
- Basculer : `export APP_ENV=dev; export TF_VAR_app_env=$APP_ENV`.

Architecture cible  
Kubernetes  
├─ infra : traefik, external-dns, cert-manager (prod), velero  
├─ data : postgres (statefulset+pvc), mariadb (statefulset+pvc)  
└─ apps : wordpress, n8n, crm, nextcloud, mailu

Domaines par défaut (`root_domain`)  
- wordpress `<root_domain>`  
- n8n `n8n.<root_domain>` + `webhook.<root_domain>`  
- nextcloud `cloud.<root_domain>`  
- mailu `mail.<root_domain>` + MX/SPF/DKIM/DMARC  
Overrides via variables app.

Stockage  
1) Bloc (PVC) : Postgres/MariaDB, data Nextcloud, wp-content, Mailu.  
2) Objet (Spaces/MinIO) : médias WordPress, backups DB/Nextcloud/Mailu, stockage externe Nextcloud optionnel.  
Ne pas utiliser S3 comme FS principal pour DB/Nextcloud.

Applications  
- WordPress : DB MariaDB, PVC wp-content, plugin S3 optionnel, ingress cert-manager, FQDN `<root_domain>`.  
- n8n : DB Postgres partagée, S3 optionnel, ingress, FQDN `n8n.<root_domain>` + webhooks.  
- CRM : Postgres prioritaire (MariaDB si incompatible), S3 éventuel.  
- Nextcloud : Postgres, data PVC, S3 externe optionnel, FQDN `cloud.<root_domain>`.  
- Mailu : chart officiel, PV bloc, DNS mail via external-dns, backups Spaces, FQDN `mail.<root_domain>`.

Backups Velero  
- Prod : bucket DO Spaces, planifié 03:00 quotidien, rétention 30 jours, cible namespace `data`.  
- Dev : MinIO + hostPath (si `enable_velero=true`).

Ajout d’app (cluster live)  
- Module dédié (namespace apps/<app>, ingress Traefik, chart non-Bitnami).  
- Ajouter creds dans `postgres_app_credentials` ou `mariadb_app_credentials`.  
- Si DB déjà en place, créer DB+user manuellement avant déploiement (init non rejoué).  
- external-dns/cert-manager gèrent DNS/ACME quand l’ingress est appliqué.

Règles IA  
- 100% auto-hébergé, pas de DB managée.  
- Tech autorisées : DigitalOcean, Kubernetes, OpenTofu, Helm, PVC bloc, Spaces/MinIO.  
- Séparer stateful (PVC) et objet (Spaces/MinIO).  
- Architecture modulaire (infra, data, apps).  
- DB Postgres par défaut ; MariaDB seulement si l’app ne supporte pas Postgres (ex : WordPress).  
- Bannir Bitnami.
