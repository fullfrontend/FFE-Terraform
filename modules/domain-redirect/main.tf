locals {
  hosts = [var.source_domain, "www.${var.source_domain}"]

  https_annotations = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
    "traefik.ingress.kubernetes.io/router.priority"    = "1"
    "cert-manager.io/cluster-issuer"                   = "letsencrypt-prod"
    "traefik.ingress.kubernetes.io/router.tls"         = "true"
  }

  http_annotations = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    "traefik.ingress.kubernetes.io/router.priority"    = "1"
  }
}

resource "kubernetes_config_map_v1" "redirect_nginx" {
  metadata {
    name      = "${var.name}-nginx"
    namespace = var.namespace
  }

  data = {
    "default.conf" = <<-EOT
      server {
        listen 80 default_server;
        server_name _;

        location / {
          return 301 ${trim(var.target_url, "/")}$request_uri;
        }
      }
    EOT
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
        volume {
          name = "nginx-config"

          config_map {
            name = kubernetes_config_map_v1.redirect_nginx.metadata[0].name
          }
        }

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

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d/default.conf"
            sub_path   = "default.conf"
            read_only  = true
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
