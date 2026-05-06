locals {
  hosts = [var.source_domain, "www.${var.source_domain}"]

  https_annotations = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
    "traefik.ingress.kubernetes.io/router.middlewares" = "${var.namespace}-${var.name}-redirect@kubernetescrd,infra-redirect-https@kubernetescrd"
    "cert-manager.io/cluster-issuer"                   = "letsencrypt-prod"
    "traefik.ingress.kubernetes.io/router.tls"         = "true"
  }

  http_annotations = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    "traefik.ingress.kubernetes.io/router.middlewares" = "${var.namespace}-${var.name}-redirect@kubernetescrd"
  }
}

resource "kubernetes_manifest" "redirect" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name}-redirect"
      namespace = var.namespace
    }
    spec = {
      redirectRegex = {
        regex       = "https?://(?:www\\.)?${replace(replace(var.source_domain, ".", "\\."), "-", "\\-")}/?(.*)"
        replacement = "${trim(var.target_url, "/")}/$1"
        permanent   = true
      }
    }
  }
}

resource "kubernetes_deployment" "dummy" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        container {
          name  = "dummy"
          image = "nginx:alpine"

          port {
            name           = "http"
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "10m"
              memory = "16Mi"
            }
            limits = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "dummy" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.name
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "https" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = var.name
    namespace   = var.namespace
    annotations = local.https_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = local.hosts
      secret_name = var.tls_secret_name
    }

    dynamic "rule" {
      for_each = local.hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.dummy.metadata[0].name
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
}

resource "kubernetes_ingress_v1" "http" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = "${var.name}-http"
    namespace   = var.namespace
    annotations = local.http_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = local.hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.dummy.metadata[0].name
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
}

resource "kubernetes_ingress_v1" "plain" {
  count = var.enable_tls ? 0 : 1

  metadata {
    name        = var.name
    namespace   = var.namespace
    annotations = local.http_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = local.hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.dummy.metadata[0].name
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
}
