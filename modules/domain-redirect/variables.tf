variable "namespace" {
  type        = string
  default     = "infra"
  description = "Namespace K8S pour le redirecteur"
}

variable "name" {
  type        = string
  description = "Nom logique du redirecteur"
}

variable "source_domain" {
  type        = string
  description = "Domaine source à rediriger (ex: he8us.be ou stage.example.com)"
}

variable "include_www" {
  type        = bool
  default     = true
  description = "Rediriger aussi le sous-domaine www du domaine source"
}

variable "target_url" {
  type        = string
  description = "URL cible complete du redirect"
}

variable "ingress_class_name" {
  type        = string
  default     = "traefik"
  description = "IngressClassName"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/cert-manager pour les hosts rediriges"
}

variable "tls_secret_name" {
  type        = string
  default     = "domain-redirect-tls"
  description = "Secret TLS pour l'ingress de redirect"
}
