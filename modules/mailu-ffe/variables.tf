variable "namespace" {
  type        = string
  default     = "mailu"
  description = "Namespace K8S pour Mailu"
}

variable "chart_version" {
  type        = string
  default     = ""
  description = "Version du chart Mailu (laisser vide pour dernière)"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClassName (ex: traefik en prod, nginx en dev)"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour Mailu (webmail/admin)"
}

variable "domain" {
  type        = string
  description = "Domaine principal mail (root_domain)"
}

variable "tls_secret_name" {
  type        = string
  description = "Secret TLS pour l’ingress Mailu"
}

variable "db_host" {
  type        = string
  description = "Hôte Postgres pour Mailu"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres pour Mailu"
}

variable "db_name" {
  type        = string
  description = "Nom de base Postgres pour Mailu"
}

variable "db_user" {
  type        = string
  description = "Utilisateur Postgres pour Mailu"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe Postgres pour Mailu"
}

variable "secret_key" {
  type        = string
  sensitive   = true
  description = "Clé secrète Mailu (16+ caractères)"
}

variable "admin_username" {
  type        = string
  description = "Utilisateur admin initial"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe admin initial"
}
