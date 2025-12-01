resource "kubernetes_namespace" "analytics" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "analytics"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}

resource "helm_release" "vince" {
  name       = "vince"
  namespace  = kubernetes_namespace.analytics.metadata[0].name

  repository      = "https://vinceanalytics.com/charts"
  chart           = "vince"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  dynamic "set" {
    for_each = length(var.domains) > 0 ? var.domains : []
    content {
      name  = "domains[${set.key}]"
      value = set.value
    }
  }

  set {
    name  = "baseURL"
    value = "https://${var.host}"
  }

  set {
    name  = "secret.adminName"
    value = var.admin_username
  }

  set_sensitive {
    name  = "secret.adminPassword"
    value = var.admin_password
  }
}

resource "kubernetes_ingress_v1" "analytics" {
  metadata {
    name      = "analytics"
    namespace = kubernetes_namespace.analytics.metadata[0].name
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.host
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = helm_release.vince.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.host]
      secret_name = var.tls_secret_name
    }
  }
}
