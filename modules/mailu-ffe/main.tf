/*
  Mailu Helm release (ingress managed externally in ingress.tf)
  - External Postgres
  - Traefik ingress handled via separate resources
*/
resource "helm_release" "mailu" {
  name      = "mailu"
  namespace = kubernetes_namespace.mailu.metadata[0].name

  repository      = "https://mailu.github.io/helm-charts/"
  chart           = "mailu"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = [
    { name = "mailu.domain", value = var.domain },
    { name = "mailu.hostnames[0]", value = var.host },
    { name = "database.type", value = "postgresql" },
    { name = "database.host", value = var.db_host },
    { name = "database.port", value = var.db_port },
    { name = "database.database", value = var.db_name },
    { name = "database.user", value = var.db_user },
    { name = "ingress.enabled", value = false },
    { name = "persistence.storageClass", value = "" },
    { name = "mailu.initialAccount.username", value = var.admin_username },
    { name = "mailu.initialAccount.domain", value = var.domain }
  ]

  set_sensitive = [
    { name = "database.password", value = var.db_password },
    { name = "mailu.secretKey", value = var.secret_key },
    { name = "mailu.initialAccount.password", value = var.admin_password }
  ]
}
