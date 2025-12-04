output "postgres_service_fqdn" {
  value       = "${kubernetes_service.postgres.metadata[0].name}.${kubernetes_namespace.data.metadata[0].name}.svc.cluster.local"
  description = "Internal FQDN for the Postgres service"
}

output "mariadb_service_fqdn" {
  value       = "${kubernetes_service.mariadb.metadata[0].name}.${kubernetes_namespace.data.metadata[0].name}.svc.cluster.local"
  description = "Internal FQDN for the MariaDB service"
}
