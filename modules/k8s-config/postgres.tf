locals {
  postgres_init_creds = length(var.postgres_app_credentials) > 0 ? merge(
    { for idx, app in var.postgres_app_credentials : "DB_${idx}" => app.db_name },
    { for idx, app in var.postgres_app_credentials : "DB_USER_${idx}" => app.user },
    { for idx, app in var.postgres_app_credentials : "DB_PASSWORD_${idx}" => app.password }
  ) : {}
}

resource "kubernetes_job" "postgres_init" {
  count = length(var.postgres_app_credentials) > 0 ? 1 : 0

  metadata {
    name      = "postgres-init"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      app = "postgres"
      job = "postgres-init"
    }
  }

  spec {
    backoff_limit              = 15
    ttl_seconds_after_finished = 120

    template {
      metadata {
        labels = {
          app = "postgres"
          job = "postgres-init"
        }
      }

      spec {
        restart_policy = "OnFailure"

        /*
            Night falling
            Sparks lighting the sleepy brain
            Night magic happens

            If you need to touch this, may the force be with you.
            Baloo.

            One-shot init:
            - reads app creds from secret
            - waits for Postgres
            - creates roles + databases
            - TTL removes the Job when done
        */
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
              escape_sql() { printf "%s" "$1" | sed "s/'/''/g"; }
              for i in $(seq 0 $((APP_COUNT-1))); do
                db_var=$(printf 'DB_%s' "$i")
                user_var=$(printf 'DB_USER_%s' "$i")
                pass_var=$(printf 'DB_PASSWORD_%s' "$i")

                db_name="$(printenv "$db_var")"
                db_user="$(printenv "$user_var")"
                db_password="$(printenv "$pass_var")"

                if [ -z "$db_name" ] || [ -z "$db_user" ] || [ -z "$db_password" ]; then
                  echo "Missing creds for index $i (db=$db_name user=$db_user), skipping"
                  continue
                fi

                db_q="$(escape_sql "$db_name")"
                user_q="$(escape_sql "$db_user")"
                pass_q="$(escape_sql "$db_password")"

                psql -v ON_ERROR_STOP=1 \
                  -v db="$db_q" \
                  -v db_user="$user_q" \
                  -v db_pass="$pass_q" \
                  -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<'SQL'
\set ON_ERROR_STOP on

SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'db_user', :'db_pass')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'db_user')
\gexec

SELECT format('CREATE DATABASE %I OWNER %I', :'db', :'db_user')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'db')
\gexec

SELECT format('GRANT ALL PRIVILEGES ON DATABASE %I TO %I', :'db', :'db_user')
\gexec
SQL
              done
            EOF
          ]

          env {
            name  = "POSTGRES_HOST"
            value = kubernetes_service.postgres.metadata[0].name
          }
          env {
            name  = "POSTGRES_PORT"
            value = "5432"
          }
          env {
            name  = "POSTGRES_USER"
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

          env {
            name  = "APP_COUNT"
            value = tostring(length(var.postgres_app_credentials))
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_init[0].metadata[0].name
            }
          }
        }

      }
    }
  }

  /* Do not block Terraform on job completion (logs inspected separately) */
  wait_for_completion = false

  depends_on = [
    kubernetes_service.postgres,
    kubernetes_secret.postgres_init,
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

          resources {
            requests = {
              cpu = "200m"
            }
            limits = {
              cpu    = "400m"
              memory = "768Mi"
            }
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
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-data"

          persistent_volume_claim {
            claim_name = "postgres-data"
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

/*
    App-facing secrets: consumed by apps (host/port/db/user/password).
    Init secrets live in data namespace (postgres-initdb) and are admin-only.
*/
// moved to secrets.tf
