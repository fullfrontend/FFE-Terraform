output "namespace" {
  value = kubernetes_namespace.wordpress.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.wordpress.metadata[0].name
}
