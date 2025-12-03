resource "kubernetes_namespace" "mailu" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "mailu"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}

resource "helm_release" "mailu" {
  name      = "mailu"
  namespace = kubernetes_namespace.mailu.metadata[0].name

  /*
      Mailu helm chart wired to:
      - external Postgres
      - Traefik ingress
  */
  repository      = "https://mailu.github.io/helm-charts/"
  chart           = "mailu"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "mailu.domain"
      value = var.domain
    },
    {
      name  = "mailu.hostnames[0]"
      value = var.host
    },
    {
      name  = "database.type"
      value = "postgresql"
    },
    {
      name  = "database.host"
      value = var.db_host
    },
    {
      name  = "database.port"
      value = var.db_port
    },
    {
      name  = "database.database"
      value = var.db_name
    },
    {
      name  = "database.user"
      value = var.db_user
    },
    {
      name  = "ingress.enabled"
      value = true
    },
    {
      name  = "ingress.className"
      value = var.ingress_class_name
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
      name  = "ingress.tls[0].hosts[0]"
      value = var.host
    },
    {
      name  = "ingress.tls[0].secretName"
      value = var.tls_secret_name
    },
    {
      name  = "persistence.storageClass"
      value = ""
    },
    {
      name  = "mailu.initialAccount.username"
      value = var.admin_username
    },
    {
      name  = "mailu.initialAccount.domain"
      value = var.domain
    }
  ]

  set_sensitive = [
    {
      name  = "database.password"
      value = var.db_password
    },
    {
      name  = "mailu.secretKey"
      value = var.secret_key
    },
    {
      name  = "mailu.initialAccount.password"
      value = var.admin_password
    }
  ]
}
