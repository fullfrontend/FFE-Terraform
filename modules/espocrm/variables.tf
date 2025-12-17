variable "namespace" {
  type        = string
  default     = "espocrm"
  description = "Namespace K8S pour EspoCRM"
}

variable "host" {
  type        = string
  description = "FQDN ingress pour EspoCRM"
}

variable "tls_secret_name" {
  type        = string
  description = "Secret TLS pour l’ingress EspoCRM"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClassName (traefik prod, nginx dev)"
}

variable "enable_tls" {
  type        = bool
  default     = true
  description = "Activer TLS/cert-manager pour EspoCRM"
}

variable "image" {
  type        = string
  description = "Image EspoCRM"
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Réplicas EspoCRM"
}

variable "storage_size" {
  type        = string
  default     = "10Gi"
  description = "Taille du PVC EspoCRM (/var/www/html)"
}

variable "storage_class_name" {
  type        = string
  default     = ""
  description = "StorageClass pour le PVC EspoCRM (vide = défaut cluster)"
}

variable "db_host" {
  type        = string
  description = "Host MariaDB pour EspoCRM"
}

variable "db_port" {
  type        = number
  description = "Port MariaDB pour EspoCRM"
}

variable "db_name" {
  type        = string
  description = "Nom de DB MariaDB pour EspoCRM"
}

variable "db_user" {
  type        = string
  description = "Utilisateur DB MariaDB pour EspoCRM"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe DB MariaDB pour EspoCRM"
}

variable "admin_user" {
  type        = string
  description = "Utilisateur admin EspoCRM"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe admin EspoCRM"
}

variable "admin_email" {
  type        = string
  description = "Email admin EspoCRM"
}

variable "enable_velero" {
  type        = bool
  default     = true
  description = "Activer le Schedule Velero pour le namespace EspoCRM"
}

variable "velero_namespace" {
  type        = string
  default     = "velero"
  description = "Namespace Velero (pour le Schedule)"
}

variable "crypt_key" {
  type        = string
  sensitive   = true
  description = "Clé de chiffrement EspoCRM (cryptKey)"
}

variable "hash_secret_key" {
  type        = string
  sensitive   = true
  description = "Clé secrète de hash EspoCRM (hashSecretKey)"
}

variable "password_salt" {
  type        = string
  sensitive   = true
  description = "Salt des mots de passe EspoCRM (passwordSalt)"
}
