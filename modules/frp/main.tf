locals {
  lb_name = replace(var.host, ".", "-")
  service_annotations = var.service_type == "LoadBalancer" ? {
    "external-dns.alpha.kubernetes.io/hostname"                        = var.host
    "service.beta.kubernetes.io/do-loadbalancer-name"                  = local.lb_name
    "service.beta.kubernetes.io/do-loadbalancer-protocol"              = "tcp"
    "service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol" = "false"
  } : {}

  frps_config = join("\n", compact([
    "bindAddr = \"0.0.0.0\"",
    format("bindPort = %d", var.bind_port),
    var.enable_kcp ? format("kcpBindPort = %d", var.kcp_bind_port) : "",
    format("vhostHTTPPort = %d", var.vhost_http_port),
    format("transport.tls.force = %t", var.transport_tls_force),
    format("webServer.addr = %q", "0.0.0.0"),
    format("webServer.port = %d", var.dashboard_port),
    format("webServer.user = %q", var.dashboard_user),
    format("webServer.password = %q", var.dashboard_password),
    "enablePrometheus = true",
    format("auth.method = %q", "token"),
    format("auth.token = %q", var.auth_token),
    "log.to = \"console\"",
    "log.level = \"info\"",
    "allowPorts = [",
    format("  { start = %d, end = %d }", var.allow_ports_start, var.allow_ports_end),
    "]",
  ]))

  tunnel_annotations_https = merge(
    {
      "kubernetes.io/ingress.class"                      = var.ingress_class_name
      "kubernetes.io/ingress.allow-http"                 = "true"
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
    },
    var.enable_tls ? {
      "cert-manager.io/cluster-issuer"                   = "letsencrypt-prod"
      "traefik.ingress.kubernetes.io/router.tls"         = "true"
      "traefik.ingress.kubernetes.io/router.middlewares" = "infra-redirect-https@kubernetescrd"
    } : {}
  )

  tunnel_annotations_http_redirect = {
    "kubernetes.io/ingress.class"                      = var.ingress_class_name
    "kubernetes.io/ingress.allow-http"                 = "true"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    "traefik.ingress.kubernetes.io/router.middlewares" = "infra-redirect-https@kubernetescrd"
  }
}

resource "kubernetes_secret_v1" "frps_config" {
  metadata {
    name      = "frps-config"
    namespace = kubernetes_namespace.frp.metadata[0].name
  }

  data = {
    "frps.toml" = local.frps_config
  }
}

resource "kubernetes_deployment" "frps" {
  lifecycle {
    precondition {
      condition     = var.dashboard_password != "" && var.auth_token != ""
      error_message = "frps requires dashboard_password and auth_token."
    }
  }

  metadata {
    name      = "frps"
    namespace = kubernetes_namespace.frp.metadata[0].name
    labels = {
      app = "frps"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frps"
      }
    }

    template {
      metadata {
        labels = {
          app = "frps"
        }
      }

      spec {
        container {
          name  = "frps"
          image = var.image
          args  = ["-c", "/etc/frp/frps.toml"]

          port {
            name           = "frps-tcp"
            container_port = var.bind_port
            protocol       = "TCP"
          }

          dynamic "port" {
            for_each = var.enable_kcp ? [1] : []
            content {
              name           = "frps-kcp"
              container_port = var.kcp_bind_port
              protocol       = "UDP"
            }
          }

          port {
            name           = "dashboard"
            container_port = var.dashboard_port
            protocol       = "TCP"
          }

          port {
            name           = "vhost-http"
            container_port = var.vhost_http_port
            protocol       = "TCP"
          }

          readiness_probe {
            tcp_socket {
              port = var.bind_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            tcp_socket {
              port = var.bind_port
            }
            initial_delay_seconds = 15
            period_seconds        = 15
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/frp"
            read_only  = true
          }
        }

        volume {
          name = "config"
          secret {
            secret_name = kubernetes_secret_v1.frps_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "frps" {
  metadata {
    name        = "frps"
    namespace   = kubernetes_namespace.frp.metadata[0].name
    annotations = local.service_annotations
    labels = {
      app = "frps"
    }
  }

  spec {
    selector = {
      app = "frps"
    }

    type = var.service_type

    port {
      name        = "frps-tcp"
      port        = var.bind_port
      target_port = var.bind_port
      protocol    = "TCP"
    }

    dynamic "port" {
      for_each = var.enable_kcp ? [1] : []
      content {
        name        = "frps-kcp"
        port        = var.kcp_bind_port
        target_port = var.kcp_bind_port
        protocol    = "UDP"
      }
    }

    port {
      name        = "dashboard"
      port        = var.dashboard_port
      target_port = var.dashboard_port
      protocol    = "TCP"
    }

    port {
      name        = "vhost-http"
      port        = var.vhost_http_port
      target_port = var.vhost_http_port
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "dashboard_https" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = "frps-dashboard"
    namespace   = kubernetes_namespace.frp.metadata[0].name
    annotations = local.tunnel_annotations_https
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = [var.dashboard_host]
      secret_name = var.dashboard_tls_secret_name
    }

    rule {
      host = var.dashboard_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.frps.metadata[0].name
              port {
                name = "dashboard"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "dashboard_http_redirect" {
  count = var.enable_tls ? 1 : 0

  metadata {
    name        = "frps-dashboard-http"
    namespace   = kubernetes_namespace.frp.metadata[0].name
    annotations = local.tunnel_annotations_http_redirect
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.dashboard_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.frps.metadata[0].name
              port {
                name = "dashboard"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "dashboard_plain" {
  count = var.enable_tls ? 0 : 1

  metadata {
    name      = "frps-dashboard"
    namespace = kubernetes_namespace.frp.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = var.ingress_class_name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.dashboard_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.frps.metadata[0].name
              port {
                name = "dashboard"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "frps_http_hosts_https" {
  count = length(var.http_hosts) > 0 && var.enable_tls ? 1 : 0

  metadata {
    name        = "frps-http"
    namespace   = kubernetes_namespace.frp.metadata[0].name
    annotations = local.tunnel_annotations_https
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = var.http_hosts
      secret_name = var.tunnel_tls_secret_name
    }

    dynamic "rule" {
      for_each = var.http_hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.frps.metadata[0].name
                port {
                  name = "vhost-http"
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "frps_http_hosts_redirect" {
  count = length(var.http_hosts) > 0 && var.enable_tls ? 1 : 0

  metadata {
    name        = "frps-http-redirect"
    namespace   = kubernetes_namespace.frp.metadata[0].name
    annotations = local.tunnel_annotations_http_redirect
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = var.http_hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.frps.metadata[0].name
                port {
                  name = "vhost-http"
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "frps_http_hosts_plain" {
  count = length(var.http_hosts) > 0 && !var.enable_tls ? 1 : 0

  metadata {
    name      = "frps-http"
    namespace = kubernetes_namespace.frp.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = var.ingress_class_name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = var.http_hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.frps.metadata[0].name
                port {
                  name = "vhost-http"
                }
              }
            }
          }
        }
      }
    }
  }
}
