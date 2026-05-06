locals {
  opencloud_annotations_https = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
    "traefik.ingress.kubernetes.io/router.middlewares" = "infra-redirect-https@kubernetescrd"
    "cert-manager.io/cluster-issuer"                   = "letsencrypt-prod"
    "traefik.ingress.kubernetes.io/router.tls"         = "true"
  }

  opencloud_annotations_http_redirect = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    "traefik.ingress.kubernetes.io/router.middlewares" = "infra-redirect-https@kubernetescrd"
  }
}

resource "kubernetes_ingress_v1" "opencloud_https" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = "opencloud"
    namespace   = kubernetes_namespace.opencloud.metadata[0].name
    annotations = local.opencloud_annotations_https
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = [var.host]
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
              name = kubernetes_service_v1.opencloud.metadata[0].name
              port {
                number = 9200
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "opencloud_http_redirect" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = "opencloud-http"
    namespace   = kubernetes_namespace.opencloud.metadata[0].name
    annotations = local.opencloud_annotations_http_redirect
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
              name = kubernetes_service_v1.opencloud.metadata[0].name
              port {
                number = 9200
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "opencloud_http_plain" {
  count = var.enable_tls ? 0 : 1

  metadata {
    name      = "opencloud"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
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
              name = kubernetes_service_v1.opencloud.metadata[0].name
              port {
                number = 9200
              }
            }
          }
        }
      }
    }
  }
}
