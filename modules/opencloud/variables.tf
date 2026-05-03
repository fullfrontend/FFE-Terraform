variable "namespace" {
  type        = string
  default     = "opencloud"
  description = "Namespace K8S pour OpenCloud et Radicale"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour OpenCloud"
}

variable "tls_secret_name" {
  type        = string
  default     = "opencloud-tls"
  description = "Secret TLS pour l'ingress OpenCloud"
}

variable "ingress_class_name" {
  type        = string
  default     = "traefik"
  description = "IngressClassName (ex: traefik en prod, nginx en dev)"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/cert-manager pour l'ingress OpenCloud"
}

variable "image" {
  type        = string
  default     = "opencloudeu/opencloud:4.0.5"
  description = "Image OpenCloud officielle"
}

variable "radicale_image" {
  type        = string
  default     = "opencloudeu/radicale:latest"
  description = "Image Radicale utilisée avec OpenCloud"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe initial de l'admin OpenCloud"
}

variable "config_storage_size" {
  type        = string
  default     = "2Gi"
  description = "Taille du PVC de configuration OpenCloud"
}

variable "data_storage_size" {
  type        = string
  default     = "50Gi"
  description = "Taille du PVC de données OpenCloud"
}

variable "radicale_storage_size" {
  type        = string
  default     = "5Gi"
  description = "Taille du PVC de données Radicale"
}

variable "enable_velero" {
  type        = bool
  default     = true
  description = "Activer la création du Schedule Velero pour OpenCloud"
}

variable "velero_namespace" {
  type        = string
  default     = "velero"
  description = "Namespace Velero (pour le Schedule)"
}
