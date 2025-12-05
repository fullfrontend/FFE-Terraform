/*
  n8n Helm release (ingress managed externally in ingress.tf)
*/
resource "helm_release" "n8n" {
  name      = "n8n"
  namespace = kubernetes_namespace.n8n.metadata[0].name

  repository      = "https://community-charts.github.io/helm-charts"
  chart           = "n8n"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = concat(
    [
      { name = "db.type", value = "postgresdb" },
      { name = "postgresql.enabled", value = false },
      { name = "externalPostgresql.host", value = var.db_host },
      { name = "externalPostgresql.port", value = var.db_port },
      { name = "externalPostgresql.database", value = var.db_name },
      { name = "externalPostgresql.username", value = var.db_user },
      { name = "ingress.enabled", value = false },
      { name = "redis.enabled", value = true },
      { name = "worker.mode", value = "queue" },
      { name = "webhook.mode", value = "queue" },
      { name = "webhook.mcp.enabled", value = true },
      { name = "webhook.url", value = "https://${var.webhook_host}" },
      { name = "main.extraEnvVars.GENERIC_TIMEZONE", value = "Europe/Brussels" },
      { name = "main.extraEnvVars.N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE", value = "true" },
      { name = "main.extraEnvVars.N8N_BLOCK_ENV_ACCESS_IN_NODE", value = "true" },
      { name = "main.extraEnvVars.N8N_GIT_NODE_DISABLE_BARE_REPOS", value = "true" }
    ],
    []
  )

  set_sensitive = [
    {
      name  = "externalPostgresql.password"
      value = var.db_password
    }
  ]
}
