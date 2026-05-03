locals {
  opencloud_url = format("%s://%s", var.enable_tls ? "https" : "http", var.host)

  opencloud_proxy_yaml = <<-EOT
    additional_policies:
      - name: default
        routes:
          - endpoint: /caldav/
            backend: http://radicale:5232
            remote_user_header: X-Remote-User
            skip_x_access_token: true
            additional_headers:
              - X-Script-Name: /caldav
          - endpoint: /.well-known/caldav
            backend: http://radicale:5232
            remote_user_header: X-Remote-User
            skip_x_access_token: true
            additional_headers:
              - X-Script-Name: /caldav
          - endpoint: /carddav/
            backend: http://radicale:5232
            remote_user_header: X-Remote-User
            skip_x_access_token: true
            additional_headers:
              - X-Script-Name: /carddav
          - endpoint: /.well-known/carddav
            backend: http://radicale:5232
            remote_user_header: X-Remote-User
            skip_x_access_token: true
            additional_headers:
              - X-Script-Name: /carddav
  EOT

  radicale_config = <<-EOT
    [server]
    hosts = 0.0.0.0:5232

    [auth]
    type = http_x_remote_user

    [storage]
    predefined_collections = {
        "def-addressbook": {
           "D:displayname": "Personal Address Book",
           "tag": "VADDRESSBOOK"
        },
        "def-calendar": {
           "C:supported-calendar-component-set": "VEVENT,VJOURNAL,VTODO",
           "D:displayname": "Personal Calendar",
           "tag": "VCALENDAR"
        }
      }

    [web]
    type = ${var.enable_radicale_debug_ui ? "internal" : "none"}
  EOT
}

resource "kubernetes_config_map_v1" "opencloud_config" {
  metadata {
    name      = "opencloud-config"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  data = {
    "proxy.yaml" = local.opencloud_proxy_yaml
  }
}

resource "kubernetes_config_map_v1" "radicale_config" {
  metadata {
    name      = "radicale-config"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  data = {
    "config" = local.radicale_config
  }
}

resource "kubernetes_persistent_volume_claim_v1" "opencloud_config" {
  metadata {
    name      = "opencloud-config"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.config_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "opencloud_data" {
  metadata {
    name      = "opencloud-data"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.data_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "radicale_data" {
  metadata {
    name      = "radicale-data"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.radicale_storage_size
      }
    }
  }
}

resource "kubernetes_deployment" "radicale" {
  metadata {
    name      = "radicale"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
    labels = {
      app = "radicale"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "radicale"
      }
    }

    template {
      metadata {
        labels = {
          app = "radicale"
        }
      }

      spec {
        security_context {
          fs_group = 1000
        }

        container {
          name  = "radicale"
          image = var.radicale_image

          security_context {
            run_as_user  = 1000
            run_as_group = 1000
          }

          port {
            name           = "http"
            container_port = 5232
            protocol       = "TCP"
          }

          readiness_probe {
            tcp_socket {
              port = 5232
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            tcp_socket {
              port = 5232
            }
            initial_delay_seconds = 15
            period_seconds        = 15
          }

          resources {
            requests = {
              cpu    = "25m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "150m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/radicale/config"
            sub_path   = "config"
            read_only  = true
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/radicale"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map_v1.radicale_config.metadata[0].name
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.radicale_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "radicale" {
  metadata {
    name      = "radicale"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  spec {
    selector = {
      app = "radicale"
    }

    port {
      name        = "http"
      port        = 5232
      target_port = 5232
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_deployment" "opencloud" {
  lifecycle {
    precondition {
      condition     = var.admin_password != ""
      error_message = "opencloud requires admin_password."
    }
  }

  metadata {
    name      = "opencloud"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
    labels = {
      app = "opencloud"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "opencloud"
      }
    }

    template {
      metadata {
        labels = {
          app = "opencloud"
        }
      }

      spec {
        security_context {
          fs_group = 1000
        }

        container {
          name    = "opencloud"
          image   = var.image
          command = ["/bin/sh", "-c"]
          args    = ["opencloud init || true; opencloud server"]

          security_context {
            run_as_user  = 1000
            run_as_group = 1000
          }

          env {
            name  = "OC_URL"
            value = local.opencloud_url
          }

          env {
            name  = "PROXY_TLS"
            value = "false"
          }

          env {
            name  = "OC_INSECURE"
            value = "false"
          }

          env {
            name  = "PROXY_ENABLE_BASIC_AUTH"
            value = "false"
          }

          env {
            name  = "IDM_ADMIN_PASSWORD"
            value = var.admin_password
          }

          env {
            name  = "OC_LOG_LEVEL"
            value = "info"
          }

          env {
            name  = "OC_LOG_COLOR"
            value = "false"
          }

          env {
            name  = "OC_LOG_PRETTY"
            value = "false"
          }

          port {
            name           = "http"
            container_port = 9200
            protocol       = "TCP"
          }

          readiness_probe {
            tcp_socket {
              port = 9200
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          liveness_probe {
            tcp_socket {
              port = 9200
            }
            initial_delay_seconds = 20
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }

          volume_mount {
            name       = "config-pvc"
            mount_path = "/etc/opencloud"
          }

          volume_mount {
            name       = "data-pvc"
            mount_path = "/var/lib/opencloud"
          }

          volume_mount {
            name       = "opencloud-config"
            mount_path = "/etc/opencloud/proxy.yaml"
            sub_path   = "proxy.yaml"
            read_only  = true
          }
        }

        volume {
          name = "config-pvc"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.opencloud_config.metadata[0].name
          }
        }

        volume {
          name = "data-pvc"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.opencloud_data.metadata[0].name
          }
        }

        volume {
          name = "opencloud-config"
          config_map {
            name = kubernetes_config_map_v1.opencloud_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.radicale]
}

resource "kubernetes_service_v1" "opencloud" {
  metadata {
    name      = "opencloud"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  spec {
    selector = {
      app = "opencloud"
    }

    port {
      name        = "http"
      port        = 9200
      target_port = 9200
      protocol    = "TCP"
    }
  }
}
