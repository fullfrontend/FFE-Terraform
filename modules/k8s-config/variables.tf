variable "cluster_name" {
  type = string
}

variable "cluster_id" {
  type = string
}


variable "do_token" {
  type        = string
  sensitive   = true
  description = "DigitalOcean API token (pour external-dns)"
}

# Velero (Spaces S3 pour backups)
variable "enable_velero" {
  type        = bool
  default     = false
  description = "Activer le déploiement Velero"
}

variable "velero_bucket" {
  type        = string
  default     = ""
  description = "Bucket Spaces pour Velero"
}

variable "velero_region" {
  type        = string
  default     = "fra1"
  description = "Région Spaces"
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
