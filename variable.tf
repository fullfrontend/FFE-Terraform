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

# N8N (base de données Postgres externe)
variable "n8n_db_host" {
  type        = string
  default     = "postgres.data.svc.cluster.local"
  description = "Hôte Postgres partagé pour n8n"
}

variable "n8n_db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres partagé pour n8n"
}

variable "n8n_db_name" {
  type        = string
  default     = "n8n"
  description = "Nom de base pour n8n"
}

variable "n8n_db_user" {
  type        = string
  default     = "n8n"
  description = "Utilisateur Postgres pour n8n"
}

variable "n8n_db_password" {
  type        = string
  default     = ""
  description = "Mot de passe Postgres pour n8n (à définir)"
  sensitive   = true
}

variable "n8n_chart_version" {
  type        = string
  default     = ""
  description = "Version du chart n8n (vide = dernière)"
}

# WordPress (MariaDB externe)
variable "wp_tls_secret_name" {
  type        = string
  default     = "wordpress-tls"
  description = "Secret TLS pour l’ingress WordPress"
}

variable "wp_db_host" {
  type        = string
  default     = "mariadb.data.svc.cluster.local"
  description = "Hôte MariaDB pour WordPress"
}

variable "wp_db_port" {
  type        = number
  default     = 3306
  description = "Port MariaDB pour WordPress"
}

variable "wp_db_name" {
  type        = string
  default     = "wordpress"
  description = "Nom de base pour WordPress"
}

variable "wp_db_user" {
  type        = string
  default     = "wordpress"
  description = "Utilisateur MariaDB pour WordPress"
}

variable "wp_db_password" {
  type        = string
  default     = ""
  description = "Mot de passe MariaDB pour WordPress (à définir)"
  sensitive   = true
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

# Nextcloud (Postgres externe)
variable "nextcloud_tls_secret_name" {
  type        = string
  default     = "nextcloud-tls"
  description = "Secret TLS pour l’ingress Nextcloud"
}

variable "nextcloud_db_host" {
  type        = string
  default     = "postgres.data.svc.cluster.local"
  description = "Hôte Postgres pour Nextcloud"
}

variable "nextcloud_db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres pour Nextcloud"
}

variable "nextcloud_db_name" {
  type        = string
  default     = "nextcloud"
  description = "Nom de base Postgres pour Nextcloud"
}

variable "nextcloud_db_user" {
  type        = string
  default     = "nextcloud"
  description = "Utilisateur Postgres pour Nextcloud"
}

variable "nextcloud_db_password" {
  type        = string
  default     = ""
  description = "Mot de passe Postgres pour Nextcloud"
  sensitive   = true
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

# Mailu (Postgres externe)
variable "mailu_tls_secret_name" {
  type        = string
  default     = "mailu-tls"
  description = "Secret TLS pour l’ingress Mailu"
}

variable "mailu_db_host" {
  type        = string
  default     = "postgres.data.svc.cluster.local"
  description = "Hôte Postgres pour Mailu"
}

variable "mailu_db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres pour Mailu"
}

variable "mailu_db_name" {
  type        = string
  default     = "mailu"
  description = "Nom de base Postgres pour Mailu"
}

variable "mailu_db_user" {
  type        = string
  default     = "mailu"
  description = "Utilisateur Postgres pour Mailu"
}

variable "mailu_db_password" {
  type        = string
  default     = ""
  description = "Mot de passe Postgres pour Mailu"
  sensitive   = true
}

variable "mailu_secret_key" {
  type        = string
  default     = ""
  description = "Clé secrète Mailu (16+ chars)"
  sensitive   = true
}

variable "mailu_admin_username" {
  type        = string
  default     = "admin"
  description = "Utilisateur admin initial Mailu"
}

variable "mailu_admin_password" {
  type        = string
  default     = ""
  description = "Mot de passe admin initial Mailu"
  sensitive   = true
}

variable "mailu_chart_version" {
  type        = string
  default     = ""
  description = "Version du chart Mailu (vide = dernière)"
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
  default     = "20Gi"
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
  default     = "20Gi"
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

variable "doks_node_size" {
  type        = string
  default     = "s-1vcpu-2gb"
  description = "K8S cluster Droplet nodes size"
}

# Velero (Spaces S3 pour backups)
variable "velero_bucket" {
  type        = string
  default     = "velero-backups"
  description = "Bucket Spaces pour Velero en prod (DO Spaces)"
}

variable "velero_s3_url" {
  type        = string
  default     = ""
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
