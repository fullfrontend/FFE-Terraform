variable "namespace" {
  type        = string
  default     = "postiz"
  description = "Namespace K8S pour Postiz"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour Postiz"
}

variable "tls_secret_name" {
  type        = string
  default     = "postiz-tls"
  description = "Secret TLS pour l'ingress Postiz"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClassName (ex: traefik en prod, nginx en dev)"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/cert-manager pour l'ingress Postiz"
}

variable "chart_version" {
  type        = string
  default     = ""
  description = "Version du chart Helm Postiz (vide = dernière)"
}

variable "storage_size" {
  type        = string
  default     = "5Gi"
  description = "Taille du PVC pour les uploads Postiz"
}

variable "storage_class_name" {
  type        = string
  default     = ""
  description = "StorageClass pour le PVC Postiz (vide = storageclass par défaut)"
}

variable "db_host" {
  type        = string
  description = "Host Postgres externe pour Postiz"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "Port Postgres pour Postiz"
}

variable "db_name" {
  type        = string
  description = "Nom de la base Postiz"
}

variable "db_user" {
  type        = string
  description = "Utilisateur Postgres Postiz"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe Postgres Postiz"
}

variable "jwt_secret" {
  type        = string
  sensitive   = true
  description = "JWT secret pour Postiz"
}

variable "redis_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe Redis Postiz"
}

variable "redis_storage_size" {
  type        = string
  default     = "1Gi"
  description = "Taille du PVC Redis Postiz"
}

variable "disable_registration" {
  type        = bool
  default     = false
  description = "Désactiver les nouvelles inscriptions Postiz après le premier compte"
}

variable "email_provider" {
  type        = string
  default     = ""
  description = "Provider email Postiz: vide, resend ou nodemailer"
}

variable "email_from_name" {
  type        = string
  default     = ""
  description = "Nom expéditeur des emails Postiz"
}

variable "email_from_address" {
  type        = string
  default     = ""
  description = "Adresse expéditeur des emails Postiz"
}

variable "email_host" {
  type        = string
  default     = ""
  description = "Host SMTP Postiz (nodemailer)"
}

variable "email_port" {
  type        = string
  default     = "465"
  description = "Port SMTP Postiz (nodemailer)"
}

variable "email_secure" {
  type        = string
  default     = "true"
  description = "SMTP secure pour Postiz (nodemailer)"
}

variable "email_user" {
  type        = string
  default     = ""
  description = "Utilisateur SMTP Postiz (nodemailer)"
}

variable "email_pass" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Mot de passe SMTP Postiz (nodemailer)"
}

variable "resend_api_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Clé API Resend pour Postiz"
}

variable "storage_provider" {
  type        = string
  default     = "local"
  description = "Backend de stockage Postiz: local ou cloudflare"
}

variable "cloudflare_account_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Cloudflare account ID pour Postiz"
}

variable "cloudflare_access_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Cloudflare access key pour Postiz"
}

variable "cloudflare_secret_access_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Cloudflare secret access key pour Postiz"
}

variable "cloudflare_bucketname" {
  type        = string
  default     = ""
  description = "Bucket Cloudflare R2 pour Postiz"
}

variable "cloudflare_bucket_url" {
  type        = string
  default     = ""
  description = "URL du bucket Cloudflare R2 pour Postiz"
}

variable "x_api_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "X API key pour Postiz"
}

variable "x_api_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "X API secret pour Postiz"
}

variable "linkedin_client_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "LinkedIn client ID pour Postiz"
}

variable "linkedin_client_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "LinkedIn client secret pour Postiz"
}

variable "facebook_app_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Facebook app ID pour Postiz (egalement utilise pour Instagram)"
}

variable "facebook_app_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Facebook app secret pour Postiz (egalement utilise pour Instagram)"
}

variable "youtube_client_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "YouTube client ID pour Postiz"
}

variable "youtube_client_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "YouTube client secret pour Postiz"
}

variable "tiktok_client_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "TikTok client ID pour Postiz"
}

variable "tiktok_client_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "TikTok client secret pour Postiz"
}

variable "reddit_client_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Reddit client ID pour Postiz"
}

variable "reddit_client_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Reddit client secret pour Postiz"
}

variable "github_client_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "GitHub client ID pour Postiz"
}

variable "github_client_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "GitHub client secret pour Postiz"
}

variable "enable_velero" {
  type        = bool
  default     = true
  description = "Activer le Schedule Velero pour le namespace Postiz"
}

variable "velero_namespace" {
  type        = string
  default     = "velero"
  description = "Namespace Velero (pour le Schedule)"
}
