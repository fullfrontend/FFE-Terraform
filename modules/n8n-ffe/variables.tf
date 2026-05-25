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

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/annotations cert-manager sur les ingresses n8n"
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

variable "webhook_host" {
  type        = string
  description = "FQDN dédié aux webhooks (ex: webhook.<root_domain>)"
}

variable "smtp_host" {
  type        = string
  description = "Host SMTP pour les emails système n8n"
}

variable "smtp_port" {
  type        = number
  description = "Port SMTP pour les emails système n8n"
}

variable "smtp_ssl" {
  type        = bool
  description = "Utiliser SSL direct pour SMTP n8n"
}

variable "smtp_starttls" {
  type        = bool
  description = "Utiliser STARTTLS pour SMTP n8n"
}

variable "smtp_user" {
  type        = string
  description = "Utilisateur SMTP n8n"
}

variable "smtp_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe SMTP n8n"
}

variable "smtp_sender" {
  type        = string
  description = "Adresse d'expédition SMTP n8n"
}

# Queue / Redis
variable "enable_redis" {
  type        = bool
  default     = true
  description = "Déployer un Redis dédié pour la queue n8n (chart officiel redis)"
}

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Port Redis"
}

variable "redis_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Mot de passe Redis"
}

variable "redis_db" {
  type        = number
  default     = 0
  description = "Index de DB Redis"
}

variable "redis_storage_size" {
  type        = string
  default     = "1Gi"
  description = "Taille du PVC Redis (si enable_redis=true)"
}

variable "enable_velero" {
  type        = bool
  default     = true
  description = "Activer la création du Schedule Velero pour n8n"
}

variable "velero_namespace" {
  type        = string
  default     = "velero"
  description = "Namespace Velero (pour le Schedule)"
}
