variable "namespace" {
  type        = string
  default     = "registry"
  description = "Namespace K8S pour le registre privé"
}

variable "host" {
  type        = string
  description = "FQDN pour le registre (ex: registry.<root_domain>)"
}

variable "tls_secret_name" {
  type        = string
  default     = "registry-tls"
  description = "Secret TLS pour l’ingress du registre"
}

variable "ingress_class_name" {
  type        = string
  default     = "traefik"
  description = "IngressClassName (traefik prod, nginx dev)"
}

variable "storage_size" {
  type        = string
  default     = "20Gi"
  description = "Taille du PVC pour le registre"
}

variable "htpasswd_entry" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Entrée htpasswd (user:bcrypt-hash) pour l’accès au registre"
}
