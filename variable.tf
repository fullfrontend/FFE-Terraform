variable "do_token" {}

variable "app_env" {
  type        = string
  default     = "prod"
  description = "Environnement (prod = DOKS, dev = minikube via kubeconfig)"
  validation {
    condition     = contains(["prod", "dev"], var.app_env)
    error_message = "app_env doit être 'prod' ou 'dev'."
  }
}

variable "enable_velero" {
  type        = bool
  default     = false
  description = "Activer le déploiement Velero (backups vers Spaces)"
}

# Domaine racine commun (ex: fullfrontend.test)
variable "root_domain" {
  type        = string
  default     = "fullfrontend.test"
  description = "Domaine principal pour les hosts des apps"
}

# N8N (base de données Postgres externe)
variable "n8n_host" {
  type        = string
  default     = ""
  description = "FQDN ingress pour n8n (laisser vide pour utiliser root_domain)"
}

variable "n8n_webhook_host" {
  type        = string
  default     = ""
  description = "FQDN ingress pour les webhooks n8n (laisser vide pour utiliser root_domain)"
}

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
variable "wp_host" {
  type        = string
  default     = ""
  description = "FQDN ingress pour WordPress (laisser vide pour utiliser root_domain)"
}

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
  default     = "10Gi"
  description = "Taille du PVC WordPress"
}

variable "wp_image" {
  type        = string
  default     = "wordpress:6.5-php8.2-apache"
  description = "Image WordPress (officielle, non Bitnami)"
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

variable "velero_dev_bucket" {
  type        = string
  default     = "velero-dev"
  description = "Bucket Velero pour l'environnement dev (MinIO local)"
}

variable "velero_dev_host_path" {
  type        = string
  default     = "/tmp/velero-dev"
  description = "Chemin hostPath pour stocker localement les backups Velero en dev"
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
}

variable "velero_secret_key" {
  type        = string
  default     = ""
  description = "Secret key Spaces pour Velero"
  sensitive   = true
}
