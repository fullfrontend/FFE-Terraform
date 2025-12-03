locals {
  postgres_init_sql = length(var.postgres_app_credentials) > 0 ? templatefile("${path.module}/templates/postgres-init.sql.tmpl", { apps = var.postgres_app_credentials }) : ""
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-root"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = var.postgres_root_password
  }
}

resource "kubernetes_config_map" "postgres_init" {
  count = local.postgres_init_sql != "" ? 1 : 0

  metadata {
    name      = "postgres-initdb"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = {
    "init.sql" = local.postgres_init_sql
  }
}

resource "kubernetes_job" "postgres_init" {
  count = local.postgres_init_sql != "" ? 1 : 0

  metadata {
    name      = "postgres-init"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "postgres"
      job = "postgres-init"
    }
  }

  spec {
    backoff_limit = 3

    template {
      metadata {
        labels = {
          app = "postgres"
          job = "postgres-init"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "init"
          image = var.postgres_image

          command = [
            "/bin/sh",
            "-c",
            <<-EOF
              set -e
              export PGPASSWORD="$POSTGRES_PASSWORD"
              until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER"; do
                echo "Waiting for postgres at $POSTGRES_HOST:$POSTGRES_PORT"
                sleep 2
              done
              psql -v ON_ERROR_STOP=1 -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -f /scripts/init.sql
            EOF
          ]

          volume_mount {
            name       = "init-sql"
            mount_path = "/scripts"
            read_only  = true
          }

          env {
            name = "POSTGRES_HOST"
            value = kubernetes_service.postgres.metadata[0].name
          }
          env {
            name = "POSTGRES_PORT"
            value = "5432"
          }
          env {
            name = "POSTGRES_USER"
            value = "postgres"
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
        }

        volume {
          name = "init-sql"

          config_map {
            name = kubernetes_config_map.postgres_init[0].metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.postgres,
    kubernetes_config_map.postgres_init,
  ]
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }

    selector = {
      app = "postgres"
    }
  }
}

resource "kubernetes_stateful_set_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    service_name = kubernetes_service.postgres.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = var.postgres_image

          port {
            name           = "postgres"
            container_port = 5432
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          dynamic "volume_mount" {
            for_each = local.postgres_init_sql != "" ? [1] : []
            content {
              name       = "init-sql"
              mount_path = "/docker-entrypoint-initdb.d"
            }
          }
        }

        volume {
          name = "postgres-data"

          persistent_volume_claim {
            claim_name = "postgres-data"
          }
        }

        dynamic "volume" {
          for_each = local.postgres_init_sql != "" ? [1] : []
          content {
            name = "init-sql"

            config_map {
              name = kubernetes_config_map.postgres_init[0].metadata[0].name
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "postgres-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = var.postgres_storage_size
          }
        }

        storage_class_name = var.storage_class_name != "" ? var.storage_class_name : null
      }
    }
  }
}

resource "kubernetes_secret" "postgres_apps" {
  for_each = { for app in var.postgres_app_credentials : app.name => app }

  metadata {
    name      = "postgres-${each.value.name}"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "db"                           = "postgres"
      "app"                          = each.value.name
    }
  }

  data = {
    host     = kubernetes_service.postgres.metadata[0].name
    port     = "5432"
    database = each.value.db_name
    user     = each.value.user
    password = each.value.password
  }
}
