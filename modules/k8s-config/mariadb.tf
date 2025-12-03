locals {
  mariadb_init_creds = length(var.mariadb_app_credentials) > 0 ? join("\n", [for app in var.mariadb_app_credentials : "${app.db_name}:${app.user}:${app.password}"]) : ""
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

resource "kubernetes_secret" "mariadb_init" {
  count = local.mariadb_init_creds != "" ? 1 : 0

  metadata {
    name      = "mariadb-initdb"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = {
    creds = local.mariadb_init_creds
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
        }

        volume {
          name = "mariadb-data"

          persistent_volume_claim {
            claim_name = "mariadb-data"
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

resource "kubernetes_job" "mariadb_init" {
  count = local.mariadb_init_creds != "" ? 1 : 0

  metadata {
    name      = "mariadb-init"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "mariadb"
      job = "mariadb-init"
    }
  }

  spec {
    backoff_limit              = 3
    ttl_seconds_after_finished = 120

    template {
      metadata {
        labels = {
          app = "mariadb"
          job = "mariadb-init"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "init"
          image = var.mariadb_image

          command = [
            "/bin/sh",
            "-c",
            <<-EOF
              set -e
              export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"
              until mysqladmin ping -h "$MARIADB_HOST" -P "$MARIADB_PORT" -u "$MARIADB_ROOT_USER" --silent; do
                echo "Waiting for mariadb at $MARIADB_HOST:$MARIADB_PORT"
                sleep 2
              done
              while IFS=: read -r DB_NAME DB_USER DB_PASSWORD; do
                mysql -h "$MARIADB_HOST" -P "$MARIADB_PORT" -u "$MARIADB_ROOT_USER" <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
SQL
              done </secrets/creds
            EOF
          ]

          env {
            name  = "MARIADB_HOST"
            value = kubernetes_service.mariadb.metadata[0].name
          }
          env {
            name  = "MARIADB_PORT"
            value = "3306"
          }
          env {
            name  = "MARIADB_ROOT_USER"
            value = "root"
          }
          env {
            name = "MARIADB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mariadb.metadata[0].name
                key  = "MARIADB_ROOT_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "init-creds"
            mount_path = "/secrets"
            read_only  = true
          }
        }

        volume {
          name = "init-creds"

          secret {
            secret_name = kubernetes_secret.mariadb_init[0].metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.mariadb,
    kubernetes_secret.mariadb_init,
  ]
}
