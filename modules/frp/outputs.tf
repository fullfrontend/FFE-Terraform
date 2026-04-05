output "host" {
  value       = var.host
  description = "Hostname public de frps"
}

output "dashboard_host" {
  value       = var.dashboard_host
  description = "Hostname public du dashboard frps"
}

output "bind_port" {
  value       = var.bind_port
  description = "Port TCP principal de frps"
}
