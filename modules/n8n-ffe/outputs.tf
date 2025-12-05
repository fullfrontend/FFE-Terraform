output "host" {
  value       = var.host
  description = "FQDN principal pour n8n"
}

output "webhook_host" {
  value       = var.webhook_host
  description = "FQDN webhook n8n"
}

output "tls_secret_name" {
  value       = var.tls_secret_name
  description = "Secret TLS utilisé par l'ingress n8n"
}
