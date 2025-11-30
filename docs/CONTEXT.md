Objectif  
Kubernetes sur DOKS en prod, cluster local en dev (docker-desktop), piloté via OpenTofu/Helm, avec séparation bloc/objet et backups quotidiens.

Plateforme  
- Ingress : Traefik  
- Certificats : cert-manager (prod)  
- DNS : external-dns (prod)  
- Stockage : PVC bloc (DO CSI), objet Spaces/MinIO  
- Backups : Velero (03:00 quotidien, rétention 30 jours)  
- Interdit : charts/images Bitnami

Environnements  
- prod (`APP_ENV=prod`) : DOKS, kubeconfig `${path.root}/.kube/config`, cert-manager on, Velero → Spaces (bucket auto).  
- dev (`APP_ENV=dev`) : cluster local (`~/.kube/config`, ex docker-desktop), cert-manager/off external-dns off, Velero → MinIO hostPath `./data/<cluster_name>-velero`.  
- Basculer : `export APP_ENV=dev; export TF_VAR_app_env=$APP_ENV`.

Secrets (SOPS/age)  
- Clé age générée via `bin/age-init.sh`; exporter `SOPS_AGE_KEY_FILE` et `SOPS_AGE_RECIPIENTS`.  
- Secrets chiffrés `secrets.tfvars.enc` (policy sops.yaml).  
- Wrapper tofu : `APP_ENV=... ./scripts/tofu-secrets.sh plan|apply` (décrypte en `.secrets.auto.tfvars`, nettoie).  
- Jamais de secrets en clair dans git (tfvars clairs exclus, `.secrets.auto.tfvars` ignoré).

Architecture cible  
Namespaces : infra (traefik, cert-manager, external-dns, velero), data (postgres, mariadb), apps (wordpress, n8n, crm, nextcloud, mailu).  
Stockage : PVC pour stateful (Postgres/MariaDB, Nextcloud data, wp-content, Mailu), objet pour médias/backups/S3 externes Nextcloud.  
Domaines par défaut (`root_domain`) :  
- wordpress `<root_domain>`  
- n8n `n8n.<root_domain>` + `webhook.<root_domain>`  
- nextcloud `cloud.<root_domain>`  
- mailu `mail.<root_domain>` + MX/SPF/DKIM/DMARC  
Overrides via variables app.

Applications  
- WordPress : MariaDB, PVC wp-content, plugin S3 optionnel, ingress cert-manager (prod), FQDN `<root_domain>`.  
- n8n : Postgres partagé, S3 optionnel, ingress, FQDN `n8n.<root_domain>` + webhooks.  
- CRM : Postgres prioritaire (MariaDB si incompatible), S3 éventuel.  
- Nextcloud : Postgres, data PVC, S3 externe optionnel, FQDN `cloud.<root_domain>`.  
- Mailu : chart officiel, PV bloc, DNS mail via external-dns, backups Spaces, FQDN `mail.<root_domain>`.

Règles IA  
- 100% auto-hébergé, pas de DB managée.  
- Tech autorisées : DO, Kubernetes, OpenTofu, Helm, PVC bloc, Spaces/MinIO.  
- Séparer stateful (PVC) et objet (Spaces/MinIO).  
- Architecture modulaire (infra, data, apps).  
- DB Postgres par défaut ; MariaDB seulement si l’app ne supporte pas Postgres (ex : WordPress).  
- Bannir Bitnami.
