data "digitalocean_kubernetes_versions" "current" {}


resource "digitalocean_kubernetes_cluster" "k8s" {
  name    = var.name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.current.latest_version

  maintenance_policy {
    start_time = "03:00"
    day        = "sunday"
  }

  node_pool {
    name       = "default"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.pool_min_count
    max_nodes  = var.pool_max_count
  }

}