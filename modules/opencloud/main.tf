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

resource "kubernetes_secret_v1" "opencloud_service_account" {
  metadata {
    name      = "opencloud-service-account"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  data = {
    OC_SERVICE_ACCOUNT_ID     = var.service_account_id
    OC_SERVICE_ACCOUNT_SECRET = var.service_account_secret
  }
}

resource "kubernetes_secret_v1" "opencloud_smtp" {
  metadata {
    name      = "opencloud-smtp"
    namespace = kubernetes_namespace.opencloud.metadata[0].name
  }

  data = {
    NOTIFICATIONS_SMTP_USERNAME = var.smtp_username
    NOTIFICATIONS_SMTP_PASSWORD = var.smtp_password
  }
}

resource "kubernetes_deployment" "opencloud" {
  lifecycle {
    precondition {
      condition     = var.admin_password != ""
      error_message = "opencloud requires admin_password."
    }
    precondition {
      condition     = var.service_account_id != "" && var.service_account_secret != ""
      error_message = "opencloud requires service_account_id and service_account_secret."
    }
    precondition {
      condition     = var.smtp_host != "" && var.smtp_sender != "" && (var.smtp_authentication == "none" || (var.smtp_username != "" && var.smtp_password != ""))
      error_message = "opencloud requires SMTP host and sender, plus username and password when authentication is enabled."
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
          name              = "opencloud"
          image             = var.image
          image_pull_policy = "Always"
          command           = ["/bin/sh", "-c"]
          args              = ["opencloud init || true; opencloud server"]

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

          env {
            name  = "OC_ADD_RUN_SERVICES"
            value = "notifications"
          }

          env {
            name  = "NOTIFICATIONS_WEB_UI_URL"
            value = local.opencloud_url
          }

          env {
            name  = "NOTIFICATIONS_SMTP_HOST"
            value = var.smtp_host
          }

          env {
            name  = "NOTIFICATIONS_SMTP_PORT"
            value = tostring(var.smtp_port)
          }

          env {
            name  = "NOTIFICATIONS_SMTP_SENDER"
            value = var.smtp_sender
          }

          env {
            name  = "NOTIFICATIONS_SMTP_ENCRYPTION"
            value = var.smtp_encryption
          }

          env {
            name  = "NOTIFICATIONS_SMTP_INSECURE"
            value = "false"
          }

          env {
            name  = "NOTIFICATIONS_SMTP_AUTHENTICATION"
            value = var.smtp_authentication
          }

          env {
            name = "NOTIFICATIONS_SMTP_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.opencloud_smtp.metadata[0].name
                key  = "NOTIFICATIONS_SMTP_USERNAME"
              }
            }
          }

          env {
            name = "NOTIFICATIONS_SMTP_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.opencloud_smtp.metadata[0].name
                key  = "NOTIFICATIONS_SMTP_PASSWORD"
              }
            }
          }

          env {
            name = "OC_SERVICE_ACCOUNT_ID"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.opencloud_service_account.metadata[0].name
                key  = "OC_SERVICE_ACCOUNT_ID"
              }
            }
          }

          env {
            name = "OC_SERVICE_ACCOUNT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.opencloud_service_account.metadata[0].name
                key  = "OC_SERVICE_ACCOUNT_SECRET"
              }
            }
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
