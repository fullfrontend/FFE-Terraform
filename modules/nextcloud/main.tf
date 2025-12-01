resource "kubernetes_namespace" "nextcloud" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name" = "nextcloud"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}

resource "helm_release" "nextcloud" {
  name       = "nextcloud"
  namespace  = kubernetes_namespace.nextcloud.metadata[0].name

  repository      = "https://nextcloud.github.io/helm/"
  chart           = "nextcloud"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "ingress.enabled"
      value = true
    },
    {
      name  = "ingress.className"
      value = "traefik"
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
      name  = "internalDatabase.enabled"
      value = false
    },
    {
      name  = "externalDatabase.enabled"
      value = true
    },
    {
      name  = "externalDatabase.type"
      value = "postgresql"
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
      name  = "persistence.enabled"
      value = true
    },
    {
      name  = "persistence.size"
      value = var.storage_size
    },
    {
      name  = "replicaCount"
      value = var.replicas
    }
  ]

  set_sensitive = [
    {
      name  = "externalDatabase.password"
      value = var.db_password
    }
  ]
}
