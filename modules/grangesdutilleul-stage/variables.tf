variable "namespace" {
  type        = string
  default     = "grangesdutilleul-stage"
  description = "Namespace Kubernetes du staging Granges du Tilleul"
}

variable "host" {
  type        = string
  description = "FQDN public du staging"
}

variable "tls_secret_name" {
  type        = string
  description = "Secret TLS de l'ingress"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClassName"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS et la redirection HTTP vers HTTPS"
}

variable "app_image" {
  type        = string
  description = "Image du projet Granges du Tilleul avec WordPress, thèmes, plugins et seed SQL"
}

variable "caddy_image" {
  type        = string
  default     = "caddy:2.9-alpine"
  description = "Image Caddy"
}

variable "mariadb_image" {
  type        = string
  description = "Image MariaDB utilisée par le job d'import initial"
}

variable "db_host" {
  type        = string
  description = "Hôte MariaDB"
}

variable "db_port" {
  type        = number
  default     = 3306
  description = "Port MariaDB"
}

variable "db_name" {
  type        = string
  description = "Base MariaDB"
}

variable "db_user" {
  type        = string
  description = "Utilisateur MariaDB"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe MariaDB"
}

variable "wordpress_table_prefix" {
  type        = string
  default     = "wp_"
  description = "Préfixe des tables WordPress"
}

variable "uploads_storage_size" {
  type        = string
  default     = "2Gi"
  description = "Taille du PVC wp-content/uploads"
}

variable "dockerhub_user" {
  type        = string
  default     = ""
  description = "Utilisateur Docker Hub"
}

variable "dockerhub_pat" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Token Docker Hub"
}

variable "dockerhub_email" {
  type        = string
  default     = ""
  description = "Email Docker Hub"
}

variable "enable_velero" {
  type        = bool
  default     = true
  description = "Créer la sauvegarde Velero du namespace"
}

variable "velero_namespace" {
  type        = string
  default     = "infra"
  description = "Namespace de Velero"
}
