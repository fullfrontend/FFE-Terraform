variable "namespace" {
  type        = string
  default     = "frp"
  description = "Namespace K8S pour frps"
}

variable "host" {
  type        = string
  description = "Hostname public de frps (ex: frp.<root_domain>)"
}

variable "dashboard_host" {
  type        = string
  description = "Hostname public du dashboard frps (ex: tunnels.<root_domain>)"
}

variable "service_type" {
  type        = string
  default     = "LoadBalancer"
  description = "Type de service K8S pour frps (LoadBalancer en prod, NodePort en dev)"
  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.service_type)
    error_message = "service_type doit être LoadBalancer, NodePort ou ClusterIP."
  }
}

variable "ingress_class_name" {
  type        = string
  default     = "traefik"
  description = "IngressClassName pour les routes HTTP de frps"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/cert-manager sur les ingresses HTTP FRP"
}

variable "tunnel_tls_secret_name" {
  type        = string
  default     = "frp-http-tls"
  description = "Secret TLS pour les hosts HTTP proxifiés via FRP"
}

variable "dashboard_tls_secret_name" {
  type        = string
  default     = "frp-dashboard-tls"
  description = "Secret TLS pour le dashboard FRP"
}

variable "image" {
  type        = string
  default     = "ghcr.io/fatedier/frps:v0.68.0"
  description = "Image officielle frps"
}

variable "bind_port" {
  type        = number
  default     = 7000
  description = "Port TCP principal de frps"
}

variable "dashboard_port" {
  type        = number
  default     = 7500
  description = "Port HTTP du dashboard frps"
}

variable "vhost_http_port" {
  type        = number
  default     = 8080
  description = "Port HTTP interne utilisé par frps pour router les tunnels HTTP"
}

variable "dashboard_user" {
  type        = string
  default     = "admin"
  description = "Utilisateur du dashboard frps"
}

variable "dashboard_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe du dashboard frps"
}

variable "auth_token" {
  type        = string
  sensitive   = true
  description = "Token partagé entre frps et frpc"
}

variable "enable_kcp" {
  type        = bool
  default     = false
  description = "Exposer aussi le port UDP KCP de frps"
}

variable "kcp_bind_port" {
  type        = number
  default     = 7000
  description = "Port UDP KCP de frps (si enable_kcp=true)"
}

variable "allow_ports_start" {
  type        = number
  default     = 2000
  description = "Début de plage de ports autorisée pour les proxies frpc"
}

variable "allow_ports_end" {
  type        = number
  default     = 50000
  description = "Fin de plage de ports autorisée pour les proxies frpc"
}

variable "transport_tls_force" {
  type        = bool
  default     = true
  description = "Forcer TLS entre frpc et frps"
}

variable "http_hosts" {
  type        = list(string)
  default     = []
  description = "Hosts HTTP routés par Traefik vers frps (ex: postiz.example.com)"
}
