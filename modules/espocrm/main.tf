locals {
  site_scheme = var.enable_tls ? "https" : "http"
  site_url    = format("%s://%s", local.site_scheme, var.host)
}

resource "kubernetes_deployment" "espocrm" {
  metadata {
    name      = "espocrm"
    namespace = kubernetes_namespace.espocrm.metadata[0].name
    labels = {
      app = "espocrm"
    }
  }

  /*
      EspoCRM deployment (official image):
      - external MariaDB
      - PVC on /var/www/html
  */
  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "espocrm"
      }
    }

    template {
      metadata {
        labels = {
          app = "espocrm"
        }
      }

      spec {
        container {
          name  = "espocrm"
          image = var.image

          port {
            name           = "http"
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          env {
            name = "ESPOCRM_DATABASE_HOST"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_host"
              }
            }
          }
          env {
            name = "ESPOCRM_DATABASE_PORT"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_port"
              }
            }
          }
          env {
            name = "ESPOCRM_DATABASE_NAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_name"
              }
            }
          }
          env {
            name = "ESPOCRM_DATABASE_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_user"
              }
            }
          }
          env {
            name = "ESPOCRM_DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_password"
              }
            }
          }
          env {
            name  = "ESPOCRM_SITE_URL"
            value = local.site_url
          }
          env {
            name  = "ESPOCRM_CONFIG_USE_HTTPS"
            value = var.enable_tls ? "true" : "false"
          }
          env {
            name  = "APACHE_SERVER_NAME"
            value = var.host
          }
          env {
            name = "ESPOCRM_CONFIG_CRYPT_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keys.metadata[0].name
                key  = "crypt_key"
              }
            }
          }
          env {
            name = "ESPOCRM_CONFIG_HASH_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keys.metadata[0].name
                key  = "hash_secret_key"
              }
            }
          }
          env {
            name = "ESPOCRM_CONFIG_PASSWORD_SALT"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keys.metadata[0].name
                key  = "password_salt"
              }
            }
          }
          env {
            name = "ESPOCRM_ADMIN_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin.metadata[0].name
                key  = "admin_user"
              }
            }
          }
          env {
            name = "ESPOCRM_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin.metadata[0].name
                key  = "admin_password"
              }
            }
          }
          env {
            name = "ESPOCRM_ADMIN_EMAIL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin.metadata[0].name
                key  = "admin_email"
              }
            }
          }
          env {
            name  = "ESPOCRM_LOG_TO_STDOUT"
            value = "true"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 20
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          volume_mount {
            name       = "espocrm-data"
            mount_path = "/var/www/html"
          }
        }

        volume {
          name = "espocrm-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.espocrm_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "espocrm" {
  metadata {
    name      = "espocrm"
    namespace = kubernetes_namespace.espocrm.metadata[0].name
    labels = {
      app = "espocrm"
    }
  }

  spec {
    selector = {
      app = "espocrm"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}
