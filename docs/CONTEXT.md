Objectif (IA)  
- Rappel : Kubernetes sur DOKS en prod, cluster local en dev (docker-desktop/minikube), piloté via OpenTofu/Helm.  
- Séparer bloc/objet, backups quotidiens, pas de services managés ni Bitnami.

Plateforme  
- Ingress : Traefik en prod, nginx via minikube en dev. WAF global (ModSecurity + OWASP CRS via Traefik, prod). Certificats : cert-manager (prod). DNS : external-dns (prod).  
- Stockage : PVC bloc (DO CSI) pour tout le stateful ; objet Spaces/MinIO pour médias et backups.  
- Backups : Velero (03:00, rétention 30 jours). Apps peuvent ajouter leur `Schedule` Velero.  
- Registry : Zot via ingress `registry.<root_domain>`.

Environnements  
- prod (`APP_ENV=prod`) : DOKS, kubeconfig `${path.root}/.kube/config` via `doctl ... kubeconfig save ...`, cert-manager on, external-dns on, Velero → Spaces.  
- dev (`APP_ENV=dev`) : cluster local `~/.kube/config`, cert-manager off, external-dns off, Velero → MinIO hostPath `./data/<cluster_name>`.  
- Bascule : `export APP_ENV=dev` et éventuellement `export TF_VAR_app_env=$APP_ENV`.

Secrets (SOPS/age)  
- Générer la clé (`bin/age-init.sh`), exporter `SOPS_AGE_KEY_FILE` et `SOPS_AGE_RECIPIENTS`.  
- `cp secrets.tfvars.example secrets.tfvars`, remplir, chiffrer via `bin/sops-encrypt.sh secrets.tfvars secrets.tfvars.enc` (policy `sops.yaml`).  
- Wrapper tofu : `APP_ENV=... ./scripts/tofu-secrets.sh plan|apply` (décrypte `.secrets.auto.tfvars`, nettoie).  
- Jamais de secrets en clair (tfvars clairs hors git, `.secrets.auto.tfvars` ignoré).

Architecture  
- Namespaces : infra (traefik, cert-manager, external-dns, velero), data (postgres, mariadb), metrics (kube-prometheus-stack), apps (wordpress, n8n, twenty, nextcloud WIP, analytics, registry).  
- Stockage : PVC pour stateful, objet pour médias/backups/S3 externes Nextcloud.  
- Domaines (`root_domain` uniquement, pas d’override) : prod défaut `fullfrontend.be`, dev défaut `fullfrontend.kube`. FQDN : WordPress `<root_domain>` ; n8n `n8n.<root_domain>` + webhooks `webhook.<root_domain>` ; Nextcloud `cloud.<root_domain>` (WIP) ; Analytics `insights.<root_domain>` ; Sentry `sentry.<root_domain>` ; Registry `registry.<root_domain>`.

Applications  
- WordPress : MariaDB, PVC wp-content, S3 optionnel, ingress cert-manager (prod), FQDN `<root_domain>`.  
- n8n : Postgres partagé, S3 optionnel, ingress, FQDN `n8n.<root_domain>` + webhooks.  
- CRM (Twenty) : Postgres (DB dédiée), ingress `twenty.<root_domain>`, Redis interne, stockage local éphémère (S3 optionnel non câblé).  
- Nextcloud : Postgres, PVC data, S3 externe optionnel, FQDN `cloud.<root_domain>` (déploiement en cours de dev).  
- Analytics (Vince) : ingress `insights.<root_domain>`, admin bootstrap via Helm values.  
- Sentry : ingress `sentry.<root_domain>`, chart Helm officiel, backup namespace via Velero.  
- Registry : Zot via ingress, PVC, htpasswd optionnel.  
- Init Jobs Postgres/MariaDB (TTL 120s) créent DB/user en `IF NOT EXISTS`; si recréés, n’ajoutent que le manquant.

Règles IA (ne pas oublier)  
- 100% auto-hébergé ; pas de DB managée ; pas de Bitnami.  
- Technologies autorisées : DO, Kubernetes, OpenTofu, Helm, PVC bloc, Spaces/MinIO.  
- Toujours séparer stateful (PVC) et objet (Spaces/MinIO).  
- Architecture modulaire (infra, data, apps).  
- Postgres par défaut ; MariaDB seulement si requis (WordPress).  
- kubectl OK pour debug ponctuel.
