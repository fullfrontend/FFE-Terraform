variable "namespace" {
  type        = string
  default     = "nextcloud"
  description = "Namespace K8S pour Nextcloud"
}

variable "chart_version" {
  type        = string
  default     = ""
  description = "Version du chart Nextcloud (laisser vide pour dernière)"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour Nextcloud"
}

variable "tls_secret_name" {
  type        = string
  default     = "nextcloud-tls"
  description = "Secret TLS pour l’ingress Nextcloud"
}

variable "db_host" {
  type        = string
  description = "Hôte Postgres pour Nextcloud"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres pour Nextcloud"
}

variable "db_name" {
  type        = string
  default     = "nextcloud"
  description = "Nom de base Postgres pour Nextcloud"
}

variable "db_user" {
  type        = string
  default     = "nextcloud"
  description = "Utilisateur Postgres pour Nextcloud"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe Postgres pour Nextcloud"
}

variable "storage_size" {
  type        = string
  default     = "50Gi"
  description = "Taille du PVC Nextcloud"
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Réplicas Nextcloud"
}
