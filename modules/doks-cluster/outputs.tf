output "cluster_id" {
  value = digitalocean_kubernetes_cluster.k8s.id
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.k8s.name
}

output "urns" {
  value = {
    cluster = digitalocean_kubernetes_cluster.k8s.urn
  }
}