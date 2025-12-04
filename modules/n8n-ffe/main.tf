resource "kubernetes_namespace" "n8n" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "n8n"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}

resource "helm_release" "n8n" {
  name      = "n8n"
  namespace = kubernetes_namespace.n8n.metadata[0].name

  /*
      n8n Helm chart configured for:
      - external Postgres
      - Redis queue mode
  */
  repository      = "https://community-charts.github.io/helm-charts"
  chart           = "n8n"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = concat([
    {
      name  = "db.type"
      value = "postgresdb"
    },
    {
      name  = "postgresql.enabled"
      value = false
    },
    {
      name  = "externalPostgresql.host"
      value = var.db_host
    },
    {
      name  = "externalPostgresql.port"
      value = var.db_port
    },
    {
      name  = "externalPostgresql.database"
      value = var.db_name
    },
    {
      name  = "externalPostgresql.username"
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
      name  = "ingress.hosts[0].paths[0].path"
      value = "/"
    },
    {
      name  = "ingress.hosts[0].paths[0].pathType"
      value = "Prefix"
    },
    {
      name  = "ingress.hosts[1].host"
      value = var.webhook_host
    },
    {
      name  = "ingress.hosts[1].paths[0].path"
      value = "/"
    },
    {
      name  = "ingress.hosts[1].paths[0].pathType"
      value = "Prefix"
    },
    {
      name  = "ingress.className"
      value = var.ingress_class_name
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
    },
    {
      name  = "main.extraEnvVars.GENERIC_TIMEZONE"
      value = "Europe/Brussels"
    },
    {
      name  = "main.extraEnvVars.N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE"
      value = "true"
    },
    {
      name  = "main.extraEnvVars.N8N_BLOCK_ENV_ACCESS_IN_NODE"
      value = "true"
    },
    {
      name  = "main.extraEnvVars.N8N_GIT_NODE_DISABLE_BARE_REPOS"
      value = "true"
    }
  ], var.enable_tls ? [
    {
      name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "letsencrypt-prod"
    },
    {
      name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.tls"
      value = "true"
    },
    {
      name  = "ingress.tls[0].hosts[0]"
      value = var.host
    },
    {
      name  = "ingress.tls[0].hosts[1]"
      value = var.webhook_host
    },
    {
      name  = "ingress.tls[0].secretName"
      value = "n8n-tls"
    }
  ] : [])

  set_sensitive = [
    {
      name  = "externalPostgresql.password"
      value = var.db_password
    }
  ]

}
