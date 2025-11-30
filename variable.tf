variable "do_token" {}
#variable "pvt_key" {}

variable "enable_velero" {
  type        = bool
  default     = false
  description = "Activer le déploiement Velero (backups vers Spaces)"
}

# Domaine racine commun (ex: example.com)
variable "root_domain" {
  type        = string
  default     = "fullfrontend.test"
  description = "Domaine principal pour les hosts des apps"
}

variable "do_region" {
  type        = string
  default     = "fra1"
  description = "Digital Ocean classic droplets region of creation"
}


# DigitalOcean Kubernetes Cluster
variable "doks_region" {
  type        = string
  default     = "fra1"
  description = "DigitalOcean Kubernetes region"
}

variable "doks_name" {
  type        = string
  default     = "ffe-k8s"
  description = "K8S Cluster name"
}

variable "doks_node_size" {
  type        = string
  default     = "s-1vcpu-2gb"
  description = "K8S cluster Droplet nodes size"
}