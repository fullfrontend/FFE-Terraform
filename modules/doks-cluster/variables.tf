variable "region" {
  type = string
  description = "DigitalOcean Kubernetes region"
}

variable "name" {
  type = string
  description = "K8S Cluster name"
}

variable "node_size" {
  type = string
  description = "K8S cluster Droplet nodes size"
}

variable "pool_min_count" {
  type = number
  description = "K8S cluster minimal nodes count"
}

variable "pool_max_count" {
  type = number
  description = "K8S cluster maximal nodes count"
}

variable "write_kubeconfig" {
  type = bool
  default = false
  description = "Should we write the Kubeconfig on disk ?"
}