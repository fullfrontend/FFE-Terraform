locals {
  mariadb_init_creds = length(var.mariadb_app_credentials) > 0 ? merge(
    { for idx, app in var.mariadb_app_credentials : "DB_${idx}" => app.db_name },
    { for idx, app in var.mariadb_app_credentials : "DB_USER_${idx}" => app.user },
    { for idx, app in var.mariadb_app_credentials : "DB_PASSWORD_${idx}" => app.password }
  ) : {}
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
  count = length(var.mariadb_app_credentials) > 0 ? 1 : 0

  metadata {
    name      = "mariadb-initdb"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = local.mariadb_init_creds
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
        /*
            StatefulSet for MariaDB
            - only root password here
            - app DB/users handled by init Job
        */
        container {
          name  = "mariadb"
          image = var.mariadb_image

          port {
            name           = "mysql"
            container_port = 3306
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

/*
    App-facing secrets: consumed by apps (host/port/db/user/password).
    Init secrets live in data namespace (mariadb-initdb) and are admin-only.
*/
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
  count = length(var.mariadb_app_credentials) > 0 ? 1 : 0

  metadata {
    name      = "mariadb-init"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "mariadb"
      job = "mariadb-init"
    }
  }

  spec {
    backoff_limit              = 15
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

        /*
            One-shot init:
            - waits for MariaDB
            - creates DB/user per app from secret
            - TTL cleans up the Job
        */
        /*
            One-shot init:
            - waits for MariaDB
            - creates DB/user per app from secret
            - TTL cleans up the Job
        */
        container {
          name  = "init"
          image = var.mariadb_image

          command = [
            "/bin/sh",
            "-c",
            <<-EOF
              set -e
              escape_ident() { printf "%s" "$1" | sed 's/`/``/g'; }
              escape_literal() { printf "%s" "$1" | sed "s/'/''/g"; }

              export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"
              until mariadb -h "$MARIADB_HOST" -P "$MARIADB_PORT" -u "$MARIADB_ROOT_USER" -e "SELECT 1" >/dev/null 2>&1; do
                echo "Waiting for mariadb at $MARIADB_HOST:$MARIADB_PORT"
                sleep 2
              done

              for i in $(seq 0 $((APP_COUNT-1))); do
                db_var=$(printf 'DB_%s' "$i")
                user_var=$(printf 'DB_USER_%s' "$i")
                pass_var=$(printf 'DB_PASSWORD_%s' "$i")

                DB_NAME="$(printenv "$db_var")"
                DB_USER="$(printenv "$user_var")"
                DB_PASSWORD="$(printenv "$pass_var")"

                if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
                  echo "Missing creds for index $i (db=$DB_NAME user=$DB_USER), skipping"
                  continue
                fi

                DB_NAME_ESC="$(escape_ident "$DB_NAME")"
                DB_USER_ESC="$(escape_literal "$DB_USER")"
                DB_PASSWORD_ESC="$(escape_literal "$DB_PASSWORD")"

                mariadb -h "$MARIADB_HOST" -P "$MARIADB_PORT" -u "$MARIADB_ROOT_USER" <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME_ESC\`;
CREATE USER IF NOT EXISTS '$DB_USER_ESC'@'%' IDENTIFIED BY '$DB_PASSWORD_ESC';
GRANT ALL PRIVILEGES ON \`$DB_NAME_ESC\`.* TO '$DB_USER_ESC'@'%';
FLUSH PRIVILEGES;
SQL
              done
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

          env {
            name  = "APP_COUNT"
            value = tostring(length(var.mariadb_app_credentials))
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.mariadb_init[0].metadata[0].name
            }
          }
        }
      }
    }
  }

  /* Do not block Terraform on job completion (logs inspected separately) */
  wait_for_completion = false

  depends_on = [
    kubernetes_service.mariadb,
    kubernetes_secret.mariadb_init,
  ]
}
