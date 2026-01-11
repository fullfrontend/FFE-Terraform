/*
    Global WAF via Traefik plugin (ModSecurity + OWASP CRS)
    - ModSecurity container acts as inspection engine
    - Dummy upstream keeps WAF responses 200 on allow
*/
resource "kubernetes_deployment" "waf_dummy" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-dummy"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-dummy"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "waf-dummy"
      }
    }

    template {
      metadata {
        labels = {
          app = "waf-dummy"
        }
      }

      spec {
        container {
          name  = "waf-dummy"
          image = var.waf_dummy_image

          port {
            name           = "http"
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "waf_dummy" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-dummy"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-dummy"
    }
  }

  spec {
    selector = {
      app = "waf-dummy"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "waf_modsecurity" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-modsecurity"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-modsecurity"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "waf-modsecurity"
      }
    }

    template {
      metadata {
        labels = {
          app = "waf-modsecurity"
        }
      }

      spec {
        container {
          name  = "waf-modsecurity"
          image = var.waf_modsecurity_image

          env {
            name  = "PROXY_UPSTREAM"
            value = "http://waf-dummy.${kubernetes_namespace.infra.metadata[0].name}.svc.cluster.local"
          }

          port {
            name           = "http"
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "waf_modsecurity" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-modsecurity"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-modsecurity"
    }
  }

  spec {
    selector = {
      app = "waf-modsecurity"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "waf_middleware" {
  count      = var.is_prod && var.enable_waf ? 1 : 0
  depends_on = [helm_release.traefik]

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "waf"
      namespace = kubernetes_namespace.infra.metadata[0].name
    }
    spec = {
      plugin = {
        modsecurity = {
          modSecurityUrl = "http://waf-modsecurity.${kubernetes_namespace.infra.metadata[0].name}.svc.cluster.local"
          maxBodySize    = var.waf_max_body_size
          timeoutMillis  = var.waf_timeout_ms
        }
      }
    }
  }
}
