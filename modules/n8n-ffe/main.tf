resource "helm_release" "n8n" {
  name       = "n8n"
  namespace  = kubernetes_namespace.n8n.metadata[0].name
  repository = "https://community-charts.github.io/helm-charts"
  chart      = "n8n"
  version    = var.chart_version != "" ? var.chart_version : null
  force_update = true

  cleanup_on_fail = true
  atomic          = true

  set = [
    # DB Config
    { name = "db.type", value = "postgresdb" },
    { name = "externalPostgresql.host", value = var.db_host },
    { name = "externalPostgresql.port", value = var.db_port },
    { name = "externalPostgresql.database", value = var.db_name },
    { name = "externalPostgresql.username", value = var.db_user },
    { name = "externalPostgresql.existingSecret", value = kubernetes_secret.n8n_external_postgres.metadata[0].name },


    # Ingress config
    { name = "ingress.enabled", value = true },
    { name = "ingress.className", value = var.ingress_class_name },
    { name = "ingress.hosts[0].host", value = var.host },
    { name = "ingress.hosts[0].paths[0].path", value = "/" },
    { name = "ingress.hosts[0].paths[0].pathType", value = "Prefix" },
    { name = "ingress.annotations.cert-manager\\.io/cluster-issuer", value = "letsencrypt-prod" },
    { name = "ingress.annotations.kubernetes\\.io/ingress\\.allow-http", value = "'true'" },
    { name = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints", value = "web\\,websecure" },
    { name = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.middlewares", value = "infra-redirect-https@kubernetescrd" },
    { name = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.tls", value = "'true'" },
    { name = "ingress.tls[0].hosts[0]", value = var.host },
    { name = "ingress.tls[0].secretName", value = var.tls_secret_name },

    # Main node config
    { name = "main.persistence.enabled", value = true },
    { name = "main.persistence.accessMode", value = "ReadWriteOnce" },
    { name = "main.persistence.volumeName", value = "n8n-main-data" },
    { name = "main.persistence.size", value = "5Gi" },
    { name = "main.resources.requests.cpu", value = "250m" },
    { name = "main.resources.limits.cpu", value = "500m" },
    { name = "main.resources.limits.memory", value = "512Mi" },
    { name = "main.livenessProbe.initialDelaySeconds", value = 30 },
    { name = "main.livenessProbe.timeoutSeconds", value = 5 },
    { name = "main.livenessProbe.periodSeconds", value = 15 },
    { name = "main.livenessProbe.failureThreshold", value = 6 },
    { name = "main.readinessProbe.initialDelaySeconds", value = 20 },
    { name = "main.readinessProbe.timeoutSeconds", value = 5 },
    { name = "main.readinessProbe.periodSeconds", value = 10 },
    { name = "main.readinessProbe.failureThreshold", value = 6 },


    # Worker Config
    { name = "worker.mode", value = "regular" },
    { name = "worker.count", value = 1 },
    { name = "worker.waitMainNodeReady.enabled", value = true },

    # Image
    { name = "image.pullPolicy", value = "Always" },

    # Webhooks config
    //{ name = "webhook.mode", value = "regular" },
    //{ name = "webhook.count", value = 1 },
    //{ name = "webhook.waitMainNodeReady.enabled", value = true },

    # Redis config
    { name = "redis.enabled", value = false },


    # Misc
    { name = "serviceMonitor.enabled", value = true },
    { name = "encryptionKey", value = var.encryption_key },
    { name = "db.logging.enabled", value = true },
    { name = "db.logging.options", value = "error" },
    { name = "db.logging.maxQueryExecutionTime", value = 5000 },
    { name = "main.extraEnvVars.N8N_BLOCK_ENV_ACCESS_IN_NODE", value = "false" },
    { name = "main.extraEnvVars.N8N_GIT_NODE_DISABLE_BARE_REPOS", value = "true" },
  ]
}
