resource "kubernetes_namespace" "n8n" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name" = "n8n"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}

resource "helm_release" "n8n" {
  name       = "n8n"
  namespace  = kubernetes_namespace.n8n.metadata[0].name

  repository      = "https://community-charts.github.io/helm-charts"
  chart           = "n8n"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "db.type"
      value = "postgresdb"
    },
    {
      name = "postgresql.enabled"
      value = false
    },
    {
      name  = "externalDatabase.host"
      value = var.db_host
    },
    {
      name  = "externalDatabase.port"
      value = var.db_port
    },
    {
      name  = "externalDatabase.database"
      value = var.db_name
    },
    {
      name  = "externalDatabase.user"
      value = var.db_user
    },
    {
      name  = "ingress.enabled"
      value = true
    },
    {
      name  = "ingress.hosts[0].host"
      value = var.host
    },
    {
      name = "ingress.ingressClassName"
      value = "traefik"
    },
    {
      name  = "redis.enabled"
      value = true
    },
    {
      name  = "worker.mode"
      value = "queue"
    },
    {
      name  = "webhook.mode"
      value = "queue"
    },
    {
      name  = "webhook.mcp.enabled"
      value = true
    },
    {
      name  = "webhook.url"
      value = "https://${var.webhook_host}"
    }
  ]

  set_sensitive = [
    {
      name  = "externalDatabase.password"
      value = var.db_password
    }
  ]
}
