variable "namespace" {
  type        = string
  default     = "n8n"
  description = "Namespace K8S pour n8n"
}

variable "chart_version" {
  type        = string
  default     = ""
  description = "Version du chart n8n (laisser vide pour dernière)"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour n8n"
}

variable "webhook_host" {
  type        = string
  description = "FQDN ingress pour les webhooks n8n"
}

variable "db_host" {
  type        = string
  description = "Hôte Postgres partagé pour n8n"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres partagé pour n8n"
}

variable "db_name" {
  type        = string
  description = "Nom de base pour n8n"
}

variable "db_user" {
  type        = string
  description = "Utilisateur Postgres pour n8n"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe Postgres pour n8n"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClassName (ex: traefik en prod, nginx en dev)"
}
