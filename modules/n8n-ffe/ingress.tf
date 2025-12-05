locals {
  n8n_annotations_https = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
    "traefik.ingress.kubernetes.io/router.middlewares" = "infra-redirect-https@kubernetescrd"
    "cert-manager.io/cluster-issuer"                   = "letsencrypt-prod"
    "traefik.ingress.kubernetes.io/router.tls"         = "true"
  }

  n8n_annotations_http_redirect = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    "traefik.ingress.kubernetes.io/router.middlewares" = "infra-redirect-https@kubernetescrd"
  }
}

# HTTPS ingress (routes both app and webhook hosts)
resource "kubernetes_ingress_v1" "n8n_https" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = "n8n"
    namespace   = kubernetes_namespace.n8n.metadata[0].name
    annotations = local.n8n_annotations_https
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = [var.host, var.webhook_host]
      secret_name = var.tls_secret_name
    }

    rule {
      host = var.host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "n8n"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = var.webhook_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "n8n"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# HTTP-only ingress that redirects to HTTPS
resource "kubernetes_ingress_v1" "n8n_http_redirect" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = "n8n-http"
    namespace   = kubernetes_namespace.n8n.metadata[0].name
    annotations = local.n8n_annotations_http_redirect
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
              name = "n8n"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = var.webhook_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "n8n"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Plain HTTP ingress when TLS disabled (dev)
resource "kubernetes_ingress_v1" "n8n_http_plain" {
  count = var.enable_tls ? 0 : 1

  metadata {
    name      = "n8n"
    namespace = kubernetes_namespace.n8n.metadata[0].name
    annotations = {
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
              name = "n8n"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = var.webhook_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "n8n"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
