output "namespace" {
  value = kubernetes_namespace.n8n.metadata[0].name
}

output "release_name" {
  value = helm_release.n8n.name
}
