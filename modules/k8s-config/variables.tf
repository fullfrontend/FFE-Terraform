variable "cluster_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "write_kubeconfig" {
  type = bool
  default = false
  description = "Should we write the Kubeconfig on disk?"
}