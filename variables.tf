variable "do_token" {}

variable "app_env" {
  type        = string
  default     = "prod"
  description = "Environnement (prod = DOKS, dev = cluster local via kubeconfig, ex: docker-desktop)"
  validation {
    condition     = contains(["prod", "dev"], var.app_env)
    error_message = "app_env doit être 'prod' ou 'dev'."
  }
}

/* Root domains per environment */
variable "root_domain_prod" {
  type        = string
  default     = "fullfrontend.be"
  description = "Root domain in prod"
}

variable "root_domain_dev" {
  type        = string
  default     = "fullfrontend.kube"
  description = "Root domain in dev"
}

variable "enable_monitoring" {
  type        = bool
  default     = true
  description = "Activer le module monitoring (kube-prometheus-stack/Grafana)"
}

# N8N (base de données Postgres externe)
variable "enable_n8n" {
  type        = bool
  default     = true
  description = "Déployer n8n (Helm) si true"
}

variable "n8n_db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres partagé pour n8n"
}

variable "n8n_chart_version" {
  type        = string
  default     = ""
  description = "Version du chart n8n (vide = dernière)"
}

variable "n8n_encryption_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Clé de chiffrement n8n (N8N_ENCRYPTION_KEY) ; si vide, le module doit en recevoir une via tfvars"
}

# WordPress (MariaDB externe)
variable "wp_tls_secret_name" {
  type        = string
  default     = "wordpress-tls"
  description = "Secret TLS pour l’ingress WordPress"
}

variable "wp_db_port" {
  type        = number
  default     = 3306
  description = "Port MariaDB pour WordPress"
}

variable "wp_replicas" {
  type        = number
  default     = 1
  description = "Réplicas WordPress"
}

variable "wp_storage_size" {
  type        = string
  default     = "2Gi"
  description = "Taille du PVC WordPress"
}

variable "wp_image" {
  type        = string
  default     = "wordpress:6.5-php8.2-apache"
  description = "Image WordPress (officielle, non Bitnami)"
}

variable "wp_as3_provider" {
  type        = string
  default     = "do"
  description = "Provider pour AS3CF (ex: do)"
}

variable "wp_as3_access_key" {
  type        = string
  default     = ""
  description = "Access key pour AS3CF"
  sensitive   = true
}

variable "wp_as3_secret_key" {
  type        = string
  default     = ""
  description = "Secret key pour AS3CF"
  sensitive   = true
}

variable "wp_mail_from" {
  type        = string
  default     = ""
  description = "Adresse expéditeur pour WP Mail SMTP"
}

variable "wp_mail_from_name" {
  type        = string
  default     = ""
  description = "Nom expéditeur pour WP Mail SMTP"
}

variable "wp_smtp_host" {
  type        = string
  default     = ""
  description = "Host SMTP pour WP Mail SMTP"
}

variable "wp_smtp_port" {
  type        = string
  default     = "465"
  description = "Port SMTP pour WP Mail SMTP"
}

variable "wp_smtp_ssl" {
  type        = string
  default     = "ssl"
  description = "Mode SSL/TLS pour WP Mail SMTP ('', 'ssl', 'tls')"
}

variable "wp_smtp_auth" {
  type        = bool
  default     = true
  description = "Activer l'auth SMTP"
}

variable "wp_smtp_user" {
  type        = string
  default     = ""
  description = "Utilisateur SMTP"
}

variable "wp_smtp_pass" {
  type        = string
  default     = ""
  description = "Mot de passe SMTP"
  sensitive   = true
}

variable "wp_lang" {
  type        = string
  default     = "fr_FR"
  description = "Langue WordPress (constante WPLANG)"
}

# Nextcloud (Postgres externe)
variable "nextcloud_tls_secret_name" {
  type        = string
  default     = "nextcloud-tls"
  description = "Secret TLS pour l’ingress Nextcloud"
}

variable "nextcloud_db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres pour Nextcloud"
}

variable "nextcloud_replicas" {
  type        = number
  default     = 1
  description = "Réplicas Nextcloud"
}

variable "nextcloud_storage_size" {
  type        = string
  default     = "50Gi"
  description = "Taille du PVC Nextcloud"
}

variable "nextcloud_chart_version" {
  type        = string
  default     = ""
  description = "Version du chart Nextcloud (vide = dernière)"
}

# Monitoring / Grafana
variable "grafana_admin_user" {
  type        = string
  default     = "admin"
  description = "Utilisateur admin Grafana"
}

variable "grafana_admin_password" {
  type        = string
  default     = ""
  description = "Mot de passe admin Grafana"
  sensitive   = true
}

# Analytics (vince – https://www.vinceanalytics.com)
variable "analytics_tls_secret_name" {
  type        = string
  default     = "analytics-tls"
  description = "Secret TLS pour l’ingress analytics"
}

variable "analytics_domains" {
  type        = list(string)
  default     = []
  description = "Liste des domaines à ajouter par défaut dans Vince (traqués). Vide = root_domain."
}

variable "analytics_admin_username" {
  type        = string
  default     = "admin"
  description = "Compte admin initial pour Vince"
}

variable "analytics_admin_password" {
  type        = string
  default     = ""
  description = "Mot de passe admin Vince"
  sensitive   = true
}

variable "analytics_chart_version" {
  type        = string
  default     = ""
  description = "Version du chart Helm Vince (vide = dernière)"
}

# Postgres (data)
variable "postgres_image" {
  type        = string
  default     = "postgres:16-alpine"
  description = "Image Postgres (officielle)"
}

variable "postgres_storage_size" {
  type        = string
  default     = "5Gi"
  description = "Taille du volume Postgres"
}

variable "postgres_root_password" {
  type        = string
  default     = ""
  description = "Mot de passe superuser Postgres"
  sensitive   = true
  validation {
    condition     = length(var.postgres_root_password) > 0
    error_message = "postgres_root_password must be set (non-empty)."
  }
}

variable "postgres_app_credentials" {
  type = list(object({
    name     = string
    db_name  = string
    user     = string
    password = string
  }))
  default     = []
  description = "Liste des DB/users Postgres par application"
}

# MariaDB (data)
variable "mariadb_image" {
  type        = string
  default     = "mariadb:11.4"
  description = "Image MariaDB (officielle)"
}

variable "mariadb_storage_size" {
  type        = string
  default     = "5Gi"
  description = "Taille du volume MariaDB"
}

variable "mariadb_root_password" {
  type        = string
  default     = ""
  description = "Mot de passe root MariaDB"
  sensitive   = true
  validation {
    condition     = length(var.mariadb_root_password) > 0
    error_message = "mariadb_root_password must be set (non-empty)."
  }
}

variable "mariadb_app_credentials" {
  type = list(object({
    name     = string
    db_name  = string
    user     = string
    password = string
  }))
  default     = []
  description = "Liste des DB/users MariaDB par application"
}

# DigitalOcean Kubernetes Cluster
variable "doks_region" {
  type        = string
  default     = "fra1"
  description = "DigitalOcean Kubernetes region"
}

variable "doks_name" {
  type        = string
  default     = "ffe-k8s"
  description = "K8S Cluster name"
}

variable "create_doks_cluster" {
  type        = bool
  default     = false
  description = "Créer le cluster DOKS (mettre false si le cluster existe déjà et qu’on veut uniquement provisionner K8s/Helm)"
}

variable "doks_node_size" {
  type        = string
  default     = "s-1vcpu-2gb"
  description = "K8S cluster Droplet nodes size"
}

# Velero (Spaces S3 pour backups)
variable "velero_bucket" {
  type        = string
  default     = "velero-backups-ffe"
  description = "Bucket Spaces pour Velero en prod (DO Spaces)"
}

# Cert-manager / ACME
variable "acme_email" {
  type        = string
  default     = ""
  description = "Email pour Let's Encrypt (ex: ops@example.com). Vide = pas d'Issuer créé."
}

# Ingress TLS toggle (HTTPS/cert-manager)
variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/redirect HTTPS sur les ingresses (mettre false si DNS non prêt ou en dev)"
}

variable "enable_velero" {
  type        = bool
  default     = true
  description = "Déployer Velero et les ressources liées (schedules, node-agent)."
}

variable "extra_domain_filters" {
  type        = list(string)
  default     = ["perinatalite.be", "cloud.perinatalite.be"]
  description = "Domaines additionnels gérés par external-dns (ex: perinatalite.be, cloud.perinatalite.be)"
}

variable "velero_s3_url" {
  type        = string
  default     = "https://fra1.digitaloceanspaces.com"
  description = "Endpoint Spaces (ex: https://fra1.digitaloceanspaces.com)"
}

variable "velero_access_key" {
  type        = string
  default     = ""
  description = "Access key Spaces pour Velero"
  sensitive   = true
  validation {
    condition     = var.app_env != "prod" || length(var.velero_access_key) > 0
    error_message = "velero_access_key must be set in prod."
  }
}

variable "velero_secret_key" {
  type        = string
  default     = ""
  description = "Secret key Spaces pour Velero"
  sensitive   = true
  validation {
    condition     = var.app_env != "prod" || length(var.velero_secret_key) > 0
    error_message = "velero_secret_key must be set in prod."
  }
}

variable "minio_access_key" {
  type        = string
  default     = ""
  description = "Access key dédiée MinIO (dev)"
  sensitive   = true
  validation {
    condition     = var.app_env != "dev" || length(var.minio_access_key) > 0
    error_message = "minio_access_key must be set in dev."
  }
}

variable "minio_secret_key" {
  type        = string
  default     = ""
  description = "Secret key dédiée MinIO (dev)"
  sensitive   = true
  validation {
    condition     = var.app_env != "dev" || length(var.minio_secret_key) > 0
    error_message = "minio_secret_key must be set in dev."
  }
}

# Storage class pour les PVC (utile en dev docker-desktop)
variable "storage_class_name" {
  type        = string
  default     = ""
  description = "StorageClass pour les PVC (vide = utiliser la valeur par défaut du cluster)"
}

# Docker Hub (pull images privées)
variable "dockerhub_user" {
  type        = string
  default     = ""
  description = "Utilisateur Docker Hub (pour images privées)"
}

variable "dockerhub_pat" {
  type        = string
  default     = ""
  description = "Token/pat Docker Hub (pour images privées)"
  sensitive   = true
}

variable "dockerhub_email" {
  type        = string
  default     = ""
  description = "Email Docker Hub (optionnel, pour le secret dockerconfigjson)"
}

# Registry (zot) privé
variable "registry_htpasswd" {
  type        = string
  default     = ""
  description = "Entrée htpasswd (ex: user:$2y$... bcrypted) pour l'accès au registre privé"
  sensitive   = true
}

variable "registry_storage_backend" {
  type        = string
  default     = "local"
  description = "Backend du registre: local (PVC) ou s3 (Spaces/MinIO)"
}

variable "registry_s3_endpoint" {
  type        = string
  default     = ""
  description = "Endpoint S3 pour le registre (ex: https://nyc3.digitaloceanspaces.com ou http://minio.data.svc.cluster.local:9000)"
}

variable "registry_s3_region" {
  type        = string
  default     = ""
  description = "Région S3 (ex: nyc3)"
}

variable "registry_s3_bucket" {
  type        = string
  default     = ""
  description = "Bucket S3 utilisé par le registre"
}

variable "registry_s3_access_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Access key S3 (Spaces/MinIO)"
}

variable "registry_s3_secret_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Secret key S3 (Spaces/MinIO)"
}

variable "registry_s3_secure" {
  type        = bool
  default     = true
  description = "true si endpoint HTTPS, false si MinIO HTTP"
}
