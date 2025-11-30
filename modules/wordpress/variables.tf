variable "namespace" {
  type        = string
  default     = "wordpress"
  description = "Namespace K8S pour WordPress"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour WordPress"
}

variable "tls_secret_name" {
  type        = string
  default     = "wordpress-tls"
  description = "Secret TLS pour l’ingress WordPress"
}

variable "db_host" {
  type        = string
  description = "Hôte MariaDB externe pour WordPress"
}

variable "db_port" {
  type        = number
  default     = 3306
  description = "Port MariaDB"
}

variable "db_name" {
  type        = string
  default     = "wordpress"
  description = "Nom de base MariaDB"
}

variable "db_user" {
  type        = string
  default     = "wordpress"
  description = "Utilisateur MariaDB"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe MariaDB"
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Nombre de replicas de WordPress"
}

variable "storage_size" {
  type        = string
  default     = "10Gi"
  description = "Taille du PVC pour WordPress"
}

variable "image" {
  type        = string
  default     = "wordpress:6.5-php8.2-apache"
  description = "Image WordPress (officielle, non Bitnami)"
}
