locals {
  analytics_sets = concat(
    [for idx, d in var.domains : { name = "domains[${idx}]", value = d }],
    [
      { name = "baseURL", value = "https://${var.host}" },
      { name = "secret.adminName", value = var.admin_username }
    ]
  )
}

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
  name      = "vince"
  namespace = kubernetes_namespace.analytics.metadata[0].name

  /*
      Vince analytics helm chart with:
      - pre-seeded domains
      - admin credentials
  */
  repository      = "https://vinceanalytics.com/charts"
  chart           = "vince"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = concat(
    local.analytics_sets,
    var.enable_tls ? [
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
        name  = "ingress.tls[0].secretName"
        value = var.tls_secret_name
      }
    ] : []
  )
  set_sensitive = [
    {
      name  = "secret.adminPassword"
      value = var.admin_password
    }
  ]
}

resource "kubernetes_ingress_v1" "analytics" {
  metadata {
    name      = "analytics"
    namespace = kubernetes_namespace.analytics.metadata[0].name
    annotations = var.enable_tls ? {
      "kubernetes.io/ingress.class"              = var.ingress_class_name
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
      "traefik.ingress.kubernetes.io/router.tls" = "true"
    } : {
      "kubernetes.io/ingress.class" = var.ingress_class_name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.host
      http {
        path {
          path      = "/"
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

  dynamic "tls" {
    for_each = var.enable_tls ? [1] : []
    content {
      hosts       = [var.host]
      secret_name = var.tls_secret_name
    }
  }
  }
}
