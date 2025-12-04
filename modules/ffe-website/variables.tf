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
  description = "Secret TLS pour l’ingress WordPress"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClassName (ex: traefik en prod, nginx en dev)"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/cert-manager pour l'ingress WordPress"
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
  description = "Nom de base MariaDB"
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

variable "replicas" {
  type        = number
  default     = 1
  description = "Nombre de replicas de WordPress"
}

variable "storage_size" {
  type        = string
  description = "Taille du PVC pour WordPress"
}

variable "image" {
  type        = string
  description = "Image WordPress (officielle, non Bitnami)"
}

variable "dockerhub_user" {
  type        = string
  default     = ""
  description = "Utilisateur Docker Hub (pull image privée)"
}

variable "dockerhub_pat" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Token/pat Docker Hub (pull image privée)"
}

variable "dockerhub_email" {
  type        = string
  default     = ""
  description = "Email Docker Hub (optionnel pour le secret dockerconfigjson)"
}
