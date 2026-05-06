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
  description = "Domaine apex source a rediriger (ex: he8us.be)"
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
