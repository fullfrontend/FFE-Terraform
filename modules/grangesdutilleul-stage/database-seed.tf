resource "kubernetes_job_v1" "database_seed" {
  metadata {
    name      = "grangesdutilleul-database-seed"
    namespace = kubernetes_namespace.stage.metadata[0].name
  }

  spec {
    backoff_limit              = 15
    ttl_seconds_after_finished = 600

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "grangesdutilleul"
          "app.kubernetes.io/component" = "database-seed"
        }
      }

      spec {
        restart_policy = "OnFailure"

        init_container {
          name    = "prepare-seed"
          image   = var.app_image
          command = ["/bin/sh", "-c"]
          args    = ["cp /opt/grangesdutilleul/database/wordpress.sql /seed/wordpress.sql"]

          volume_mount {
            name       = "seed"
            mount_path = "/seed"
          }
        }

        container {
          name    = "import"
          image   = var.mariadb_image
          command = ["/bin/sh", "-c"]
          args = [<<-EOT
            set -eu
            export MYSQL_PWD="$WORDPRESS_DB_PASSWORD"

            until mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$WORDPRESS_DB_USER" "$WORDPRESS_DB_NAME" -e "SELECT 1" >/dev/null 2>&1; do
              echo "Waiting for the Granges du Tilleul database"
              sleep 2
            done

            TABLE_COUNT="$(mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$WORDPRESS_DB_USER" -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$WORDPRESS_DB_NAME'")"
            if [ "$TABLE_COUNT" = "0" ]; then
              mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$WORDPRESS_DB_USER" "$WORDPRESS_DB_NAME" < /seed/wordpress.sql
              echo "Initial WordPress database imported"
            else
              echo "Database already contains $TABLE_COUNT tables; seed import skipped"
            fi
          EOT
          ]

          env {
            name  = "DB_HOST"
            value = var.db_host
          }

          env {
            name  = "DB_PORT"
            value = tostring(var.db_port)
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.database.metadata[0].name
            }
          }

          volume_mount {
            name       = "seed"
            mount_path = "/seed"
            read_only  = true
          }
        }

        volume {
          name = "seed"
          empty_dir {}
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

  wait_for_completion = false
}
