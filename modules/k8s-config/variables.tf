variable "cluster_name" {
  type        = string
  description = "Nom du cluster (utilisé pour quelques annotations/nommage)"
}

variable "region" {
  type        = string
  description = "Région DigitalOcean (utilise doks_region)"
}

variable "kubeconfig_path" {
  type        = string
  description = "Chemin du kubeconfig (cluster local en dev, DOKS écrit par Terraform en prod)"
}

variable "is_prod" {
  type        = bool
  description = "Prod = DOKS, Dev = cluster local (ex: docker-desktop)"
}

variable "do_token" {
  type        = string
  sensitive   = true
  description = "DigitalOcean API token (pour external-dns)"
}

variable "extra_domain_filters" {
  type        = list(string)
  default     = []
  description = "Domaines additionnels gérés par external-dns (en plus de root_domain)"
}

variable "root_domain" {
  type        = string
  description = "Domaine racine (utilisé par external-dns pour filtrer/ownership TXT)"
}

# Velero (Spaces S3 pour backups)
variable "enable_velero" {
  type        = bool
  default     = false
  description = "Activer le déploiement Velero"
}

variable "enable_cert_manager" {
  type        = bool
  default     = true
  description = "Déployer cert-manager (désactivé en dev cluster local)"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/redirect sur les ingresses (false = HTTP seulement)"
}

variable "acme_email" {
  type        = string
  default     = ""
  description = "Email ACME pour cert-manager (Let's Encrypt). Vide = ne pas créer l'Issuer."
}

variable "velero_bucket" {
  type        = string
  default     = ""
  description = "Bucket Spaces pour Velero"
}

variable "velero_s3_url" {
  type        = string
  default     = ""
  description = "Endpoint Spaces (https://<region>.digitaloceanspaces.com)"
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

variable "minio_access_key" {
  type        = string
  default     = ""
  description = "Access key dédiée MinIO (dev)"
  sensitive   = true
}

variable "minio_secret_key" {
  type        = string
  default     = ""
  description = "Secret key dédiée MinIO (dev)"
  sensitive   = true
}

variable "storage_class_name" {
  type        = string
  default     = ""
  description = "StorageClass pour les PVC (vide = valeur par défaut du cluster)"
}

# Postgres (data namespace)
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

# MariaDB (data namespace)
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
