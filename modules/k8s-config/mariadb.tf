locals {
  mariadb_init_sql = length(var.mariadb_app_credentials) > 0 ? templatefile("${path.module}/templates/mariadb-init.sql.tmpl", { apps = var.mariadb_app_credentials }) : ""
}

resource "kubernetes_secret" "mariadb" {
  metadata {
    name      = "mariadb-root"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = {
    MARIADB_ROOT_PASSWORD = var.mariadb_root_password
  }
}

resource "kubernetes_config_map" "mariadb_init" {
  count = local.mariadb_init_sql != "" ? 1 : 0

  metadata {
    name      = "mariadb-initdb"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = {
    "init.sql" = local.mariadb_init_sql
  }
}

resource "kubernetes_service" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "mariadb"
    }
  }

  spec {
    port {
      name        = "mysql"
      port        = 3306
      target_port = 3306
    }

    selector = {
      app = "mariadb"
    }
  }
}

resource "kubernetes_stateful_set_v1" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "mariadb"
    }
  }

  spec {
    service_name = kubernetes_service.mariadb.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "mariadb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mariadb"
        }
      }

      spec {
        container {
          name  = "mariadb"
          image = var.mariadb_image

          port {
            name           = "mysql"
            container_port = 3306
          }

          env {
            name  = "MARIADB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_ROOT_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "mariadb-data"
            mount_path = "/var/lib/mysql"
          }

          dynamic "volume_mount" {
            for_each = local.mariadb_init_sql != "" ? [1] : []
            content {
              name       = "init-sql"
              mount_path = "/docker-entrypoint-initdb.d"
            }
          }
        }

        volume {
          name = "mariadb-data"

          persistent_volume_claim {
            claim_name = "mariadb-data"
          }
        }

        dynamic "volume" {
          for_each = local.mariadb_init_sql != "" ? [1] : []
          content {
            name = "init-sql"

            config_map {
              name = kubernetes_config_map.mariadb_init[0].metadata[0].name
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mariadb-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = var.mariadb_storage_size
          }
        }

        storage_class_name = var.storage_class_name != "" ? var.storage_class_name : null
      }
    }
  }
}

resource "kubernetes_secret" "mariadb_apps" {
  for_each = { for app in var.mariadb_app_credentials : app.name => app }

  metadata {
    name      = "mariadb-${each.value.name}"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "db"                           = "mariadb"
      "app"                          = each.value.name
    }
  }

  data = {
    host     = kubernetes_service.mariadb.metadata[0].name
    port     = "3306"
    database = each.value.db_name
    user     = each.value.user
    password = each.value.password
  }
}
