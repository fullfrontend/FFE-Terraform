variable "namespace" {
  type        = string
  default     = "analytics"
  description = "Namespace K8S pour les web-analytics"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour l’analytics"
}

variable "tls_secret_name" {
  type        = string
  description = "Secret TLS pour l’ingress analytics"
}

variable "domains" {
  type        = list(string)
  description = "Liste des domaines à pré-créer dans Vince"
}

variable "admin_username" {
  type        = string
  description = "Compte admin initial Vince"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe admin Vince"
}

variable "chart_version" {
  type        = string
  default     = ""
  description = "Version du chart Helm Vince (vide = dernière)"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClassName (ex: traefik en prod, nginx en dev)"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/cert-manager pour l'ingress analytics"
}
