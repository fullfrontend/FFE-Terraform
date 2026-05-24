locals {
  opencloud_url = format("%s://%s", var.enable_tls ? "https" : "http", var.host)
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

    strategy {
      type = "Recreate"
    }

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
      }
    }
  }
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
