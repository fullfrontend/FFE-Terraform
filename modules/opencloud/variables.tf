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


variable "enable_radicale_debug_ui" {
  type        = bool
  default     = false
  description = "Expose temporairement l'UI web interne de Radicale via un ingress dédié"
}

variable "radicale_debug_host" {
  type        = string
  default     = ""
  description = "FQDN pour l'UI debug Radicale"
}

variable "radicale_debug_tls_secret_name" {
  type        = string
  default     = "radicale-debug-tls"
  description = "Secret TLS pour l'ingress debug Radicale"
}

variable "radicale_debug_remote_user" {
  type        = string
  default     = ""
  description = "Valeur injectée dans X-Remote-User pour accéder temporairement à l'UI Radicale"
}
