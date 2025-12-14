variable "host" {
  type        = string
  description = "FQDN pour l'UI n8n"
}

variable "tls_secret_name" {
  type        = string
  default     = "n8n-tls"
  description = "Secret TLS pour l'ingress n8n"
}

variable "ingress_class_name" {
  type        = string
  default     = "traefik"
  description = "Classe d'ingress (traefik/nginx)"
}

variable "chart_version" {
  type        = string
  default     = ""
  description = "Version du chart n8n (vide = dernière)"
}

variable "db_host" {
  type        = string
  description = "Host Postgres externe"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres"
}

variable "db_name" {
  type        = string
  description = "Nom de la base n8n"
}

variable "db_user" {
  type        = string
  description = "Utilisateur Postgres n8n"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe Postgres n8n"
}

variable "encryption_key" {
  type        = string
  sensitive   = true
  description = "Clé de chiffrement n8n (N8N_ENCRYPTION_KEY)"
}
