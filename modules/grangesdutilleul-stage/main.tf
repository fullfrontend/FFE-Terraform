locals {
  app_labels = {
    "app.kubernetes.io/name"      = "grangesdutilleul"
    "app.kubernetes.io/component" = "wordpress"
  }
}

resource "kubernetes_deployment_v1" "stage" {
  metadata {
    name      = "grangesdutilleul"
    namespace = kubernetes_namespace.stage.metadata[0].name
    labels    = local.app_labels
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = local.app_labels
    }

    template {
      metadata {
        labels = local.app_labels
      }

      spec {
        security_context {
          fs_group               = 82
          fs_group_change_policy = "OnRootMismatch"
        }

        init_container {
          name    = "prepare-wordpress"
          image   = var.app_image
          command = ["/bin/sh", "-c"]
          args    = ["cp -a /var/www/html/. /runtime/"]

          volume_mount {
            name       = "runtime"
            mount_path = "/runtime"
          }
        }

        container {
          name  = "app"
          image = var.app_image

          port {
            name           = "fastcgi"
            container_port = 9000
          }

          env {
            name  = "APP_ENV"
            value = "dev"
          }

          env {
            name  = "WORDPRESS_TABLE_PREFIX"
            value = var.wordpress_table_prefix
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.database.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "750m"
              memory = "768Mi"
            }
          }

          volume_mount {
            name       = "runtime"
            mount_path = "/var/www/html"
          }

          volume_mount {
            name       = "uploads"
            mount_path = "/var/www/html/wp-content/uploads"
          }

          volume_mount {
            name       = "runtime-config"
            mount_path = "/usr/local/etc/php/conf.d/zz-dev.ini"
            sub_path   = "dev.ini"
            read_only  = true
          }
        }

        container {
          name  = "caddy"
          image = var.caddy_image

          port {
            name           = "http"
            container_port = 80
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
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
            name       = "runtime"
            mount_path = "/var/www/html"
            read_only  = true
          }

          volume_mount {
            name       = "uploads"
            mount_path = "/var/www/html/wp-content/uploads"
            read_only  = true
          }

          volume_mount {
            name       = "runtime-config"
            mount_path = "/etc/caddy/Caddyfile"
            sub_path   = "Caddyfile"
            read_only  = true
          }
        }

        volume {
          name = "runtime"
          empty_dir {}
        }

        volume {
          name = "uploads"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.uploads.metadata[0].name
          }
        }

        volume {
          name = "runtime-config"
          config_map {
            name = kubernetes_config_map_v1.runtime.metadata[0].name
          }
        }

        dynamic "image_pull_secrets" {
          for_each = var.dockerhub_user != "" ? [1] : []
          content {
            name = kubernetes_secret_v1.dockerhub[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "stage" {
  metadata {
    name      = "grangesdutilleul"
    namespace = kubernetes_namespace.stage.metadata[0].name
  }

  spec {
    selector = local.app_labels

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}
